/**
 * Canary - A free and open-source MMORPG server emulator
 * Copyright (©) 2019–present OpenTibiaBR <opentibiabr@outlook.com>
 * Repository: https://github.com/opentibiabr/canary
 * License: https://github.com/opentibiabr/canary/blob/main/LICENSE
 * Contributors: https://github.com/opentibiabr/canary/graphs/contributors
 * Website: https://docs.opentibiabr.com/
 */

#pragma once

#include <cstddef>
#include <string_view>

namespace AccountSession {

inline constexpr std::size_t rawTokenSize = 64;

[[nodiscard]] constexpr bool isValidRawToken(std::string_view token) noexcept {
	if (token.size() != rawTokenSize) {
		return false;
	}

	for (const char character : token) {
		const bool isDigit = character >= '0' && character <= '9';
		const bool isLowerHex = character >= 'a' && character <= 'f';
		const bool isUpperHex = character >= 'A' && character <= 'F';
		if (!isDigit && !isLowerHex && !isUpperHex) {
			return false;
		}
	}

	return true;
}

} // namespace AccountSession
