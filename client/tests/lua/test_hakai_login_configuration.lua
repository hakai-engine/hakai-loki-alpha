local passed, failed = 0, 0

local function test(name, callback)
    local ok, err = pcall(callback)
    if ok then
        passed = passed + 1
    else
        failed = failed + 1
        io.stderr:write(string.format('FAIL %s: %s\n', name, err))
    end
end

local function readFile(path)
    local file, err = io.open(path, 'rb')
    assert(file, string.format('unable to read %s: %s', path, tostring(err)))
    local contents = file:read('*a')
    file:close()
    return contents
end

local initSource = readFile('init.lua')
local enterGameSource = readFile('modules/client_entergame/entergame.lua')
local httpLoginSource = readFile('src/framework/net/httplogin.cpp')
local luaFunctionsSource = readFile('src/framework/luafunctions.cpp')
local clientAssetsSource = readFile('modules/client_assets/client_assets.lua')
local resourceManagerSource = readFile('src/framework/core/resourcemanager.cpp')
local thingTypeManagerSource = readFile('src/client/thingtypemanager.cpp')
local protocolGameParseSource = readFile('src/client/protocolgameparse.cpp')
local protocolGameSource = readFile('src/client/protocolgame.cpp')
local gameHeaderSource = readFile('src/client/game.h')
local luaWorkflowSource = readFile('.github/workflows/reusable-tests-lua.yml')

test('Hakai 15.25 uses the local HTTP login endpoint', function()
    assert(initSource:find('["http://127.0.0.1:8088/login"]', 1, true))
    assert(initSource:find('port = 8088', 1, true))
    assert(initSource:find('protocol = 1525', 1, true))
    assert(initSource:find('httpLogin = true', 1, true))
end)

test('unique Hakai profile initializes without the later ServerList dependency', function()
    local initStart = assert(enterGameSource:find('function EnterGame.init()', 1, true))
    local rememberCallback = assert(enterGameSource:find(
        "connect(enterGame:getChildById('rememberEmailBox')",
        initStart,
        true
    ))
    local preDependencyInit = enterGameSource:sub(initStart, rememberCallback - 1)
    assert(not preDependencyInit:find('ServerList.', 1, true))
    assert(preDependencyInit:find("g_settings.setNode('ServerList', servers)", 1, true))
    assert(enterGameSource:find('local function getUniqueServerConfig()', 1, true))
    assert(enterGameSource:find('G.host = uniqueHost', 1, true))
    assert(enterGameSource:find('httpLogin = uniqueValues.httpLogin == true', 1, true))
    assert(enterGameSource:find('httpLoginBox:setChecked(true)', 1, true))
    assert(enterGameSource:find('httpLoginBox:setEnabled(false)', 1, true))
end)

test('an explicit HTTP URL selects HTTP independently of the legacy port', function()
    assert(enterGameSource:find("G.host:match('^https?://')", 1, true))
    assert(enterGameSource:find('(hasHttpEndpoint or G.port ~= 7171)', 1, true))
end)

test('HTTP login owns, cancels, and uniquely identifies the active request', function()
    assert(enterGameSource:find('local activeHttpLogin', 1, true))
    assert(enterGameSource:find('activeHttpLogin:cancel()', 1, true))
    assert(enterGameSource:find('nextHttpRequestId = nextHttpRequestId + 1', 1, true))
    assert(not enterGameSource:find('math.random(1)', 1, true))
    assert(httpLoginSource:find('[self, host, path, port, email, password, token, request_id, httpLogin]', 1, true))
    assert(luaFunctionsSource:find('bindClassMemberFunction<LoginHttp>("cancel"', 1, true))
end)

test('HTTPS login never downgrades credentials to HTTP', function()
    assert(not httpLoginSource:find('if (!httpLogin &&', 1, true))
end)

test('HTTPS verifies certificates and all login transports have bounded timeouts', function()
    assert(httpLoginSource:find('enable_server_certificate_verification(true)', 1, true))
    assert(httpLoginSource:find('enable_server_hostname_verification(true)', 1, true))
    assert(not httpLoginSource:find('enable_server_certificate_verification(false)', 1, true))
    assert(not httpLoginSource:find('enable_server_hostname_verification(false)', 1, true))
    assert(httpLoginSource:find('set_connection_timeout(s_loginTimeoutSeconds)', 1, true))
    assert(httpLoginSource:find('set_read_timeout(s_loginTimeoutSeconds)', 1, true))
    assert(httpLoginSource:find('set_write_timeout(s_loginTimeoutSeconds)', 1, true))
    assert(httpLoginSource:find('set_follow_location(false)', 1, true))
end)

test('HTTP login declares non-persistent intent and WebAssembly accepts completed fetches', function()
    assert(httpLoginSource:find('{"stayloggedin", false}', 1, true))
    assert(not httpLoginSource:find('{"stayloggedin", true}', 1, true))
    assert(httpLoginSource:find('response.connected = true', 1, true))
end)

test('HTTP logs redact complete secrets and never emit an unparsed body', function()
    assert(httpLoginSource:find('it.value() = std::string{ s_redacted }', 1, true))
    assert(httpLoginSource:find('[unparsed-body: {} bytes]', 1, true))
    assert(not httpLoginSource:find('redactTokenLikeValue', 1, true))
    assert(not httpLoginSource:find('[unparsed-body] {}', 1, true))
end)

test('login response validation rejects malformed session and world mappings', function()
    assert(httpLoginSource:find('isOpaqueSessionKey', 1, true))
    assert(httpLoginSource:find('Invalid world entry in login response.', 1, true))
    assert(httpLoginSource:find('Character references an unknown world.', 1, true))
    assert(enterGameSource:find('pcall(json.decode, jsonWorlds)', 1, true))
    assert(enterGameSource:find('The login server returned a character for an unknown world.', 1, true))
    assert(enterGameSource:find('previewState = tonumber(world.previewstate) == 1', 1, true))
    assert(enterGameSource:find('previewState = world.previewState', 1, true))
end)

test('client CI executes every Hakai Lua contract suite', function()
    assert(luaWorkflowSource:find('tests/lua/test_hakai_login_configuration.lua', 1, true))
    assert(luaWorkflowSource:find('tests/lua/test_extended_json_protocol.lua', 1, true))
    assert(luaWorkflowSource:find('tests/lua/test_pokemon_domain.lua', 1, true))
end)

test('unverified asset archives and executable extras are disabled', function()
    assert(initSource:find('enabled = false', 1, true))
    assert(initSource:find('allowMissingPackedRawFallback = false', 1, true))
    assert(initSource:find('preferArchive = false', 1, true))
    assert(initSource:find('installArchiveExtras = false', 1, true))
    assert(initSource:find('installPackagedFiles = false', 1, true))
    assert(clientAssetsSource:find('Asset archive installation requires a pinned SHA-256.', 1, true))
    assert(clientAssetsSource:find('Strict asset installation requires a manifest SHA-256 pinned in local configuration.', 1, true))
end)

test('asset paths reject traversal before writing into the work directory', function()
    assert(clientAssetsSource:find('Unsafe asset manifest path:', 1, true))
    assert(resourceManagerSource:find('isSafeRelativeArchivePath', 1, true))
    assert(resourceManagerSource:find('Refusing unsafe downloaded-file destination', 1, true))
    assert(resourceManagerSource:find('Refusing unsafe archive destination or prefix', 1, true))
end)

test('installed asset gate requires the completion marker and every catalog entry', function()
    assert(clientAssetsSource:find('installFileExists(completeMarkerPath(version)) and hasModernClientFiles(version)', 1, true))
    assert(clientAssetsSource:find("type(entry.file) ~= 'string' or not isSafeRelativePath(entry.file)", 1, true))
    assert(not clientAssetsSource:find("if entryType == 'appearances' or entryType == 'staticdata' or entryType == 'proficiencies' then", 1, true))
end)

test('15.25 asset identifier is normalized and validated before world login', function()
    assert(thingTypeManagerSource:find('normalizedSha256', 1, true))
    assert(thingTypeManagerSource:find('find_first_not_of(" \\t\\r\\n")', 1, true))
    assert(thingTypeManagerSource:find('value.size() != 64', 1, true))
    assert(not thingTypeManagerSource:find('m_assetIdentifier = "appearancesHash"', 1, true))
end)

test('unknown server feature ids cannot crash the client', function()
    assert(protocolGameParseSource:find('featureId >= static_cast<uint8_t>(Otc::LastGameFeature)', 1, true))
    assert(protocolGameParseSource:find('catch (const std::exception& e)', 1, true))
    assert(gameHeaderSource:find('index < m_features.size()', 1, true))
end)

test('15.25 session login does not persist or retain the account password', function()
    assert(enterGameSource:find("ServerList.setServerPassword(G.host, '')", 1, true))
    assert(enterGameSource:find("g_settings.remove('password')", 1, true))
    assert(not enterGameSource:find('ServerList.setServerPassword(G.host, G.password)', 1, true))
    assert(enterGameSource:find("G.password = ''", 1, true))
    assert(protocolGameSource:find('if (g_game.getFeature(Otc::GameSessionKey))', 1, true))
    assert(protocolGameSource:find('m_accountPassword.clear()', 1, true))
    assert(protocolGameSource:find('m_authenticatorToken.clear()', 1, true))
end)

print(string.format('%d passed, %d failed', passed, failed))
os.exit(failed == 0 and 0 or 1)
