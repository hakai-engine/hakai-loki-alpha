/*
 * Copyright (c) 2010-2026 OTClient <https://github.com/edubart/otclient>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#ifndef CPPHTTPLIB_OPENSSL_SUPPORT
#    define CPPHTTPLIB_OPENSSL_SUPPORT
#endif
#ifdef __APPLE__
#    undef CPPHTTPLIB_USE_NON_BLOCKING_GETADDRINFO
#    define CPPHTTPLIB_DISABLE_MACOSX_AUTOMATIC_ROOT_CERTIFICATES
#endif
#include <httplib.h>

#include "httplogin.h"
#include <framework/core/asyncdispatcher.h>
#include <framework/core/eventdispatcher.h>
#include <framework/core/logger.h>
#include <nlohmann/json.hpp>
#include <cctype>
#include <spdlog/spdlog.h>

#ifdef __EMSCRIPTEN__
#include <emscripten/fetch.h>
#endif

using json = nlohmann::json;

namespace {
    constexpr std::string_view s_redacted = "***";
    constexpr std::size_t s_maxSanitizedBodySize = 2048;
    constexpr time_t s_loginTimeoutSeconds = 10;

    std::string toLowerCopy(const std::string_view value)
    {
        std::string out;
        out.reserve(value.size());
        for (const auto c : value) {
            out.push_back(static_cast<char>(std::tolower(static_cast<unsigned char>(c))));
        }
        return out;
    }

    bool isSensitiveRequestField(const std::string_view key)
    {
        const auto lowered = toLowerCopy(key);
        return lowered.find("password") != std::string::npos
            || lowered.find("token") != std::string::npos
            || lowered.find("session") != std::string::npos;
    }

    bool isSensitiveResponseField(const std::string_view key)
    {
        const auto lowered = toLowerCopy(key);
        return lowered.find("token") != std::string::npos
            || lowered.find("session") != std::string::npos
            || lowered.find("cookie") != std::string::npos;
    }

    bool isSensitiveHeaderKey(const std::string_view key)
    {
        const auto lowered = toLowerCopy(key);
        return lowered == "authorization"
            || lowered == "proxy-authorization"
            || lowered == "cookie"
            || lowered == "set-cookie"
            || lowered == "x-auth-token";
    }

    std::string sanitizeHeaderValue(const std::string_view key, const std::string_view value)
    {
        if (isSensitiveHeaderKey(key)) {
            return std::string{ s_redacted };
        }
        return std::string{ value };
    }

    void sanitizeJson(json& value, const bool requestBody)
    {
        if (value.is_object()) {
            for (auto it = value.begin(); it != value.end(); ++it) {
                const bool sensitiveField = requestBody ? isSensitiveRequestField(it.key()) : isSensitiveResponseField(it.key());
                if (sensitiveField) {
                    it.value() = std::string{ s_redacted };
                    continue;
                }
                sanitizeJson(it.value(), requestBody);
            }
            return;
        }

        if (value.is_array()) {
            for (auto& item : value) {
                sanitizeJson(item, requestBody);
            }
        }
    }

    std::string sanitizeHttpBody(const std::string& body, const bool requestBody)
    {
        if (body.empty()) {
            return {};
        }

        try {
            auto parsed = json::parse(body);
            sanitizeJson(parsed, requestBody);
            auto sanitized = parsed.dump();
            if (sanitized.size() <= s_maxSanitizedBodySize) {
                return sanitized;
            }
            return sanitized.substr(0, s_maxSanitizedBodySize) + "...";
        } catch (...) {
            return fmt::format("[unparsed-body: {} bytes]", body.size());
        }
    }

    std::string sanitizeRequestPath(const std::string_view path)
    {
        const auto suffix = path.find_first_of("?#");
        return std::string { path.substr(0, suffix) };
    }

    template <typename Client>
    void configureLoginClient(Client& client)
    {
        client.set_connection_timeout(s_loginTimeoutSeconds);
        client.set_read_timeout(s_loginTimeoutSeconds);
        client.set_write_timeout(s_loginTimeoutSeconds);
        client.set_follow_location(false);
    }

    bool isUnsignedInteger(const json& value)
    {
        return value.is_number_unsigned()
            || (value.is_number_integer() && value.get<int64_t>() >= 0);
    }

    bool hasNonEmptyString(const json& object, const std::string_view key)
    {
        const auto it = object.find(std::string { key });
        return it != object.end() && it->is_string() && !it->get_ref<const std::string&>().empty();
    }

    bool hasUnsignedInteger(const json& object, const std::string_view key)
    {
        const auto it = object.find(std::string { key });
        return it != object.end() && isUnsignedInteger(*it);
    }

    bool hasBoolean(const json& object, const std::string_view key)
    {
        const auto it = object.find(std::string { key });
        return it != object.end() && it->is_boolean();
    }

    bool isOpaqueSessionKey(const std::string& value)
    {
        if (value.size() != 64) {
            return false;
        }
        for (const auto c : value) {
            if (std::isxdigit(static_cast<unsigned char>(c)) == 0) {
                return false;
            }
        }
        return true;
    }
}

LoginHttp::LoginHttp() {
    this->characters.clear();
    this->worlds.clear();
    this->session.clear();
    this->errorMessage.clear();
    this->cancelled.store(false);
}

void LoginHttp::cancel() {
    cancelled.store(true);
}

void LoginHttp::Logger(const auto& req, const auto& res) {
    if (!spdlog::should_log(spdlog::level::debug)) {
        return;
    }

    const auto sanitizedRequestBody = sanitizeHttpBody(req.body, true);
    const auto sanitizedResponseBody = sanitizeHttpBody(res.body, false);

    g_logger.debug("======= HTTP LOG =======");
    g_logger.debug("-- REQUEST --");
    g_logger.debug("{}", req.method);
    g_logger.debug("{}", sanitizeRequestPath(req.path));
    g_logger.debug("{}", sanitizedRequestBody);

    for (auto itr = req.headers.begin(); itr != req.headers.end(); ++itr) {
        g_logger.debug("{}\t{}", itr->first, sanitizeHeaderValue(itr->first, itr->second));
    }
    g_logger.debug("-- RESPONSE --");
    g_logger.debug("{}", res.version);
    g_logger.debug("{}", res.status);
    g_logger.debug("{}", res.reason);
    g_logger.debug("{}", sanitizedResponseBody);
    g_logger.debug("Location: {}", res.location.empty() ? "" : "[redacted]");

    for (auto itr = res.headers.begin(); itr != res.headers.end(); ++itr) {
        g_logger.debug("{}\t{}", itr->first, sanitizeHeaderValue(itr->first, itr->second));
    }

    g_logger.debug("=========");
}

void LoginHttp::startHttpLogin(const std::string& host, const std::string& path,
                               const uint16_t port, const std::string& email,
                               const std::string& password) {
    httplib::SSLClient cli(host, port);
    configureLoginClient(cli);

    cli.set_logger(
        [this](const auto& req, const auto& res) { LoginHttp::Logger(req, res); });

    const auto body = json{ {"email", email}, {"password", password}, {"stayloggedin", false}, {"type", "login"} };
    const httplib::Headers headers = { {"User-Agent", "Mozilla/5.0"} };

    if (auto res = cli.Post(path, headers, body.dump(1), "application/json")) {
        if (res->status == 200) {
            g_logger.debug("{}", sanitizeHttpBody(res->body, false));
        }
    } else {
        const auto err = res.error();
        g_logger.warning("HTTP error: {}", to_string(err));
    }
}

std::string LoginHttp::getCharacterList() { return this->characters; }

std::string LoginHttp::getWorldList() { return this->worlds; }

std::string LoginHttp::getSession() { return this->session; }

void LoginHttp::httpLogin(const std::string& host, const std::string& path,
                          uint16_t port, const std::string& email,
                          const std::string& password, int request_id, bool httpLogin, const std::string& token) {
    const auto self = static_self_cast<LoginHttp>();
#ifndef __EMSCRIPTEN__
    this->errorMessage.clear();
    g_asyncDispatcher->detach_task(
        [self, host, path, port, email, password, token, request_id, httpLogin] {
        if (self->cancelled.load()) return;
        HttpResponse result = httpLogin
            ? self->loginHttpJson(host, path, port, email, password, token)
            : self->loginHttpsJson(host, path, port, email, password, token);

        if (result && result.status == Success && self->parseJsonResponse(result.body)) {
            g_dispatcher.addEvent([self, request_id] {
                if (self->cancelled.load()) return;
                g_lua.callGlobalField("EnterGame", "loginSuccess", request_id,
                self->getSession(), self->getWorldList(),
                self->getCharacterList());
            });
        } else {
            int status = 0;
            std::string msg = "";
            if (result) {
                status = result.status;
                if (!self->errorMessage.empty()) {
                    msg = self->errorMessage;
                }
                try {
                    const auto body = json::parse(result.body);
                    if (msg.empty()) {
                        msg = body.value("errorMessage", "");
                    }
                    status = body.value("errorCode", status);
                } catch (...) {
                }
                if (msg.empty()) {
                    if (status != Success) {
                        msg = "HTTP " + std::to_string(status);
                        if (!result.reason.empty()) {
                            msg += " - " + result.reason;
                        } else {
                            msg += " - Unknown status";
                        }
                    } else if (!self->errorMessage.empty()) {
                        msg = self->errorMessage;
                    } else {
                        msg = "Invalid response received from server (expected JSON).";
                    }
                }
            } else {
                status = -1;
                if (self->errorMessage.length() == 0) {
                    msg = "Failed to connect to login server.";
                } else {
                    msg = self->errorMessage;
                }
            }

            g_dispatcher.addEvent([self, request_id, status, msg] {
                if (self->cancelled.load()) return;
                g_lua.callGlobalField("EnterGame", "loginFailed", request_id, msg,
                status);
            });
        }
    });
#else
    this->errorMessage.clear();
    g_asyncDispatcher->detach_task(
        [self, host, path, port, email, password, token, request_id, httpLogin] {
        if (self->cancelled.load()) return;
        const auto doRequest = [&](bool useHttp) -> LoginHttp::HttpResponse {
            emscripten_fetch_attr_t attr;
            emscripten_fetch_attr_init(&attr);
            strcpy(attr.requestMethod, "POST");
            static const char* const headers[] = {
                "Content-Type", "application/json; charset=utf-8",
                0,
            };
            attr.requestHeaders = headers;
            attr.attributes = EMSCRIPTEN_FETCH_LOAD_TO_MEMORY | EMSCRIPTEN_FETCH_SYNCHRONOUS;

            json body = {
                {"email", email},
                {"password", password},
                {"stayloggedin", false},
                {"type", "login"}
            };

            if (!token.empty()) {
                body["token"] = token;
                body["authenticatorToken"] = token;
            }

            std::string bodyStr = body.dump(1);
            attr.requestData = bodyStr.data();
            attr.requestDataSize = bodyStr.length();

            const auto scheme = useHttp ? "http://" : "https://";
            std::string url = scheme + (host.length() > 0 ? host : "127.0.0.1") + ":" + std::to_string(port) + path;
            emscripten_fetch_t* fetch = emscripten_fetch(&attr, url.c_str());

            HttpResponse response;
            if (fetch) {
                response.connected = true;
                response.status = static_cast<int>(fetch->status);
                response.body.assign(fetch->data, fetch->numBytes);
                emscripten_fetch_close(fetch);
            } else {
                response.status = -1;
                if (self->errorMessage.empty()) {
                    self->errorMessage = "Failed to connect to login server.";
                }
            }
            return response;
        };

        HttpResponse result = httpLogin ? doRequest(true) : doRequest(false);

        if (self->cancelled.load()) return;
        if (result && result.status == Success && !self->parseJsonResponse(result.body)) {
            result.status = -1;
        }
        if (result && result.status == Success) {
            g_dispatcher.addEvent([self, request_id] {
                if (self->cancelled.load()) return;
                g_lua.callGlobalField("EnterGame", "loginSuccess", request_id,
                self->getSession(), self->getWorldList(),
                self->getCharacterList());
            });
        } else {
            int status = 0;
            std::string msg = "";
            status = result ? result.status : -1;
            msg = self->errorMessage.length() == 0 ? "Unknown error" : self->errorMessage;

            g_dispatcher.addEvent([self, request_id, status, msg] {
                if (self->cancelled.load()) return;
                g_lua.callGlobalField("EnterGame", "loginFailed", request_id, msg,
                status);
            });
        }
    });
#endif
}

LoginHttp::HttpResponse LoginHttp::loginHttpsJson(const std::string& host,
                                                  const std::string& path,
                                                  const uint16_t port,
                                                  const std::string& email,
                                                  const std::string& password,
                                                  const std::string& token) {
    httplib::SSLClient client(host, port);
    configureLoginClient(client);

    client.set_logger(
        [this](const auto& req, const auto& res) { LoginHttp::Logger(req, res); });

    client.set_ca_cert_path("./cacert.pem");
    client.enable_server_certificate_verification(true);
    client.enable_server_hostname_verification(true);

    json body = {
        {"email", email},
        {"password", password},
        {"stayloggedin", false},
        {"type", "login"}
    };

    if (!token.empty()) {
        body["token"] = token;
        body["authenticatorToken"] = token;
    }

    const httplib::Headers headers = { {"User-Agent", "Mozilla/5.0"} };

    httplib::Result response =
        client.Post(path, headers, body.dump(), "application/json");
    if (!response) {
        this->errorMessage = "Failed to connect to server (HTTPS). Check the address and port.";
        g_logger.warning("HTTPS error: {}", to_string(response.error()));
    } else if (response->status != Success) {
        this->errorMessage = "HTTP " + std::to_string(response->status);
        if (!response->reason.empty()) {
            this->errorMessage += " - " + response->reason;
        }
        g_logger.warning("HTTPS request returned HTTP {} {}", response->status, response->reason);
    } else {
        g_logger.debug("HTTPS status: HTTP {}", response->status);
    }

    if (!response)
        return {};

    return { true, response->status, response->reason, response->body };
}

LoginHttp::HttpResponse LoginHttp::loginHttpJson(const std::string& host,
                                                 const std::string& path,
                                                 const uint16_t port,
                                                 const std::string& email,
                                                 const std::string& password,
                                                 const std::string& token) {
    httplib::Client client(host, port);
    configureLoginClient(client);
    client.set_logger(
        [this](const auto& req, const auto& res) { LoginHttp::Logger(req, res); });

    const httplib::Headers headers = { {"User-Agent", "Mozilla/5.0"} };
    json body = {
        {"email", email},
        {"password", password},
        {"stayloggedin", false},
        {"type", "login"}
    };

    if (!token.empty()) {
        body["token"] = token;
    }

    httplib::Result response =
        client.Post(path, headers, body.dump(), "application/json");
    if (!response) {
        this->errorMessage = "Failed to connect to server (HTTP). Check the address and port.";
        g_logger.warning("HTTP error: {}", to_string(response.error()));
    } else if (response->status != Success) {
        this->errorMessage = "HTTP " + std::to_string(response->status);
        if (!response->reason.empty()) {
            this->errorMessage += " - " + response->reason;
        }
        g_logger.warning("HTTP request returned HTTP {} {}", response->status, response->reason);
    } else {
        g_logger.debug("HTTP status: HTTP {}", response->status);
    }
    if (!response)
        return {};

    return { true, response->status, response->reason, response->body };
}

bool LoginHttp::parseJsonResponse(const std::string& body) {
    if (cancelled.load()) return false;
    json responseJson;
    try {
        if (cancelled.load()) return false;
        responseJson = json::parse(body);
    } catch (...) {
        g_logger.warning("Failed to parse json response");
        this->errorMessage = "Invalid response received from server (expected JSON).";
        return false;
    }

    if (!responseJson.is_object()) {
        this->errorMessage = "Invalid login response root.";
        return false;
    }

    if (responseJson.contains("errorCode")) {
        if (!responseJson["errorCode"].is_number_integer()) {
            this->errorMessage = "Invalid errorCode in login response.";
            return false;
        }

        const auto errorCode = responseJson["errorCode"].get<int64_t>();
        if (errorCode != 0) {
            this->errorMessage = responseJson.contains("errorMessage") && responseJson["errorMessage"].is_string()
                ? responseJson["errorMessage"].get<std::string>()
                : "Login failed.";
            g_logger.debug("Login failed with error code {}.", errorCode);
            return false;
        }
    }

    if (!responseJson.contains("session") || !responseJson.contains("playdata")) {
        this->errorMessage = "Missing session or playdata.";
        return false;
    }

    const auto& sessionJson = responseJson["session"];
    const auto& playdata = responseJson["playdata"];
    if (!sessionJson.is_object() || !playdata.is_object()) {
        this->errorMessage = "Invalid session or playdata.";
        return false;
    }

    if (!hasNonEmptyString(sessionJson, "sessionkey")
        || !isOpaqueSessionKey(sessionJson["sessionkey"].get<std::string>())
        || !hasUnsignedInteger(sessionJson, "premiumuntil")) {
        this->errorMessage = "Invalid session data.";
        return false;
    }

    if (!playdata.contains("characters") || !playdata["characters"].is_array()
        || !playdata.contains("worlds") || !playdata["worlds"].is_array()) {
        this->errorMessage = "Missing characters or worlds.";
        return false;
    }

    const auto& worldsJson = playdata["worlds"];
    const auto& charactersJson = playdata["characters"];
    if (worldsJson.empty()) {
        this->errorMessage = "No game world is available.";
        return false;
    }
    if (charactersJson.empty()) {
        this->errorMessage = "This account has no character.";
        return false;
    }

    for (const auto& world : worldsJson) {
        if (!world.is_object()
            || !hasUnsignedInteger(world, "id")
            || !hasNonEmptyString(world, "name")
            || !hasNonEmptyString(world, "externaladdressprotected")
            || !hasUnsignedInteger(world, "externalportprotected")
            || !hasUnsignedInteger(world, "previewstate")
            || !hasUnsignedInteger(world, "pvptype")) {
            this->errorMessage = "Invalid world entry in login response.";
            return false;
        }

        const auto port = world["externalportprotected"].get<uint64_t>();
        if (port == 0 || port > 65535) {
            this->errorMessage = "Invalid world port in login response.";
            return false;
        }
    }

    for (const auto& character : charactersJson) {
        if (!character.is_object()
            || !hasUnsignedInteger(character, "worldid")
            || !hasNonEmptyString(character, "name")
            || !hasUnsignedInteger(character, "level")
            || !hasNonEmptyString(character, "vocation")
            || !hasUnsignedInteger(character, "dailyrewardstate")
            || !hasBoolean(character, "ishidden")
            || !hasBoolean(character, "ismaincharacter")
            || !hasUnsignedInteger(character, "outfitid")
            || !hasUnsignedInteger(character, "addonsflags")
            || !hasUnsignedInteger(character, "detailcolor")
            || !hasUnsignedInteger(character, "headcolor")
            || !hasUnsignedInteger(character, "legscolor")
            || !hasUnsignedInteger(character, "torsocolor")) {
            this->errorMessage = "Invalid character entry in login response.";
            return false;
        }

        const auto worldId = character["worldid"].get<uint64_t>();
        bool worldFound = false;
        for (const auto& world : worldsJson) {
            if (world["id"].get<uint64_t>() == worldId) {
                worldFound = true;
                break;
            }
        }
        if (!worldFound) {
            this->errorMessage = "Character references an unknown world.";
            return false;
        }
    }

    this->session = sessionJson.dump();
    this->characters = charactersJson.dump();
    this->worlds = worldsJson.dump();

    return true;
}
