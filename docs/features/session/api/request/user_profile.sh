#!/bin/bash
# user_profile - API test link + doc generator
# Usage: bash docs/features/session/api/request/user_profile.sh
#
# Tests: auth(sms+login) -> get profile -> update profile -> change avatar
#        -> set password -> duplicate 409 -> change password -> wrong 401 -> password login

BASE="http://127.0.0.1:9600"
PHONE="13800001111"
PASS=0

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOCS_DIR="$SCRIPT_DIR/../docs/user_profile"
mkdir -p "$DOCS_DIR"

step() { echo ""; echo "========== [$1] $2 =========="; }
pass() { echo "[PASS]"; PASS=$((PASS+1)); }
fail() { echo "[FAIL] $1"; exit 1; }

json_val() { echo "$1" | sed -n "s/.*\"$2\":\"\([^\"]*\)\".*/\1/p"; }
json_bool() { echo "$1" | sed -n "s/.*\"$2\":\([a-z]*\).*/\1/p"; }
json_num() { echo "$1" | sed -n "s/.*\"$2\":\([0-9]*\).*/\1/p"; }

write_doc() {
  local file="$1" method="$2" path="$3" desc="$4" param="$5" status="$6" resp="$7" curl_cmd="$8" notes="$9"
  {
    echo "# $method $path"
    echo ""; echo "$desc"; echo ""
    if [ -n "$param" ]; then
      echo "## Parameters"; echo ""
      echo '```json'; echo "$param"; echo '```'; echo ""
    fi
    echo "## Response \`$status\`"; echo ""
    echo '```json'; echo "$resp"; echo '```'; echo ""
    echo "## curl"; echo ""
    echo '```bash'; echo "$curl_cmd"; echo '```'
    [ -n "$notes" ] && echo "" && echo "> $notes"
  } > "$DOCS_DIR/$file"
}

LINK="# user_profile — API test link\n\nBase URL: \`$BASE\`\n\n| # | Interface | Status | Result | Doc |\n|---|-----------|--------|--------|-----|"
add_link() { LINK="$LINK\n| $1 | \`$2 $3\` | \`$4\` | PASS | [$5]($5) |"; }

# ─── pre: auth (get token) ───
step "pre" "POST /auth/sms + /auth/login"
SMS=$(curl -s -X POST "$BASE/auth/sms" -H "Content-Type: application/json" -d '{"phone":"'$PHONE'"}')
CODE=$(json_val "$SMS" "code")
[ -z "$CODE" ] && fail "no code"
LOGIN=$(curl -s -X POST "$BASE/auth/login" -H "Content-Type: application/json" \
  -d '{"phone":"'$PHONE'","type":"sms","credential":"'$CODE'"}')
TOKEN=$(json_val "$LOGIN" "token")
[ -z "$TOKEN" ] && fail "login failed"
echo "token acquired, user_id: $(json_num "$LOGIN" "user_id")"
pass
AUTH="Authorization: Bearer $TOKEN"

# === 1. Get profile ===
step 1 "GET /user/profile"
RESP=$(curl -s -X GET "$BASE/user/profile" -H "$AUTH")
[ -z "$(json_val "$RESP" "nickname")" ] && fail "get profile failed"
echo "nickname: $(json_val "$RESP" "nickname"), avatar: $(json_val "$RESP" "avatar"), signature: '$(json_val "$RESP" "signature")'"
echo "$(json_val "$RESP" "avatar")" | grep -q "^identicon:" || fail "avatar should be identicon"
pass
CURL="curl -s -X GET \"$BASE/user/profile\" \\
  -H \"Authorization: Bearer $TOKEN\""
write_doc "01_get_profile.md" "GET" "/user/profile" "Get current user profile. Requires Bearer token." "" "200" "$RESP" "$CURL"
add_link 1 "GET" "/user/profile" "200" "01_get_profile.md"

# === 2. Update profile ===
step 2 "PUT /user/profile - nickname + signature"
BODY='{"nickname":"TestUser","signature":"hello world"}'
RESP=$(curl -s -X PUT "$BASE/user/profile" -H "$AUTH" -H "Content-Type: application/json" -d "$BODY")
[ "$(json_val "$RESP" "nickname")" = "TestUser" ] || fail "nickname not updated"
[ "$(json_val "$RESP" "signature")" = "hello world" ] || fail "signature not updated"
echo "nickname: $(json_val "$RESP" "nickname"), signature: $(json_val "$RESP" "signature")"
pass
CURL="curl -s -X PUT \"$BASE/user/profile\" \\
  -H \"Authorization: Bearer $TOKEN\" \\
  -H \"Content-Type: application/json\" \\
  -d '$BODY'"
write_doc "02_update_profile.md" "PUT" "/user/profile" "Update user profile. All fields optional." "$BODY" "200" "$RESP" "$CURL"
add_link 2 "PUT" "/user/profile" "200" "02_update_profile.md"

# === 3. Change avatar ===
step 3 "PUT /user/profile - avatar"
BODY='{"avatar":"identicon:seed_42"}'
RESP=$(curl -s -X PUT "$BASE/user/profile" -H "$AUTH" -H "Content-Type: application/json" -d "$BODY")
[ "$(json_val "$RESP" "avatar")" = "identicon:seed_42" ] || fail "avatar not updated"
echo "avatar: $(json_val "$RESP" "avatar")"
pass
CURL="curl -s -X PUT \"$BASE/user/profile\" \\
  -H \"Authorization: Bearer $TOKEN\" \\
  -H \"Content-Type: application/json\" \\
  -d '$BODY'"
write_doc "03_change_avatar.md" "PUT" "/user/profile" "Change identicon avatar seed." "$BODY" "200" "$RESP" "$CURL"
add_link 3 "PUT" "/user/profile" "200" "03_change_avatar.md"

# === 4. Set password ===
step 4 "POST /user/password"
BODY='{"new_password":"test123456"}'
RESP=$(curl -s -X POST "$BASE/user/password" -H "$AUTH" -H "Content-Type: application/json" -d "$BODY")
echo "message: $(json_val "$RESP" "message")"
pass
CURL="curl -s -X POST \"$BASE/user/password\" \\
  -H \"Authorization: Bearer $TOKEN\" \\
  -H \"Content-Type: application/json\" \\
  -d '$BODY'"
write_doc "04_set_password.md" "POST" "/user/password" "Set password for the first time." "$BODY" "200" "$RESP" "$CURL"
add_link 4 "POST" "/user/password" "200" "04_set_password.md"

# === 5. Duplicate set password - 409 ===
step 5 "POST /user/password - expect 409"
BODY='{"new_password":"another123"}'
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/user/password" -H "$AUTH" -H "Content-Type: application/json" -d "$BODY")
[ "$HTTP_CODE" = "409" ] || fail "expected 409, got $HTTP_CODE"
echo "HTTP $HTTP_CODE Conflict"
pass
CURL="curl -s -X POST \"$BASE/user/password\" \\
  -H \"Authorization: Bearer $TOKEN\" \\
  -H \"Content-Type: application/json\" \\
  -d '$BODY'"
write_doc "05_set_password_conflict.md" "POST" "/user/password" "Set password again when already set." "$BODY" "409" "(empty body)" "$CURL" "Returns 409 if password already exists."
add_link 5 "POST" "/user/password" "409" "05_set_password_conflict.md"

# === 6. Change password ===
step 6 "PUT /user/password"
BODY='{"old_password":"test123456","new_password":"newpass789"}'
RESP=$(curl -s -X PUT "$BASE/user/password" -H "$AUTH" -H "Content-Type: application/json" -d "$BODY")
echo "message: $(json_val "$RESP" "message")"
pass
CURL="curl -s -X PUT \"$BASE/user/password\" \\
  -H \"Authorization: Bearer $TOKEN\" \\
  -H \"Content-Type: application/json\" \\
  -d '$BODY'"
write_doc "06_change_password.md" "PUT" "/user/password" "Change password. Requires old password verification." "$BODY" "200" "$RESP" "$CURL"
add_link 6 "PUT" "/user/password" "200" "06_change_password.md"

# === 7. Wrong old password - 401 ===
step 7 "PUT /user/password - expect 401"
BODY='{"old_password":"wrong","new_password":"whatever123"}'
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$BASE/user/password" -H "$AUTH" -H "Content-Type: application/json" -d "$BODY")
[ "$HTTP_CODE" = "401" ] || fail "expected 401, got $HTTP_CODE"
echo "HTTP $HTTP_CODE Unauthorized"
pass
CURL="curl -s -X PUT \"$BASE/user/password\" \\
  -H \"Authorization: Bearer $TOKEN\" \\
  -H \"Content-Type: application/json\" \\
  -d '$BODY'"
write_doc "07_change_password_wrong.md" "PUT" "/user/password" "Change password with wrong old password." "$BODY" "401" "(empty body)" "$CURL" "Returns 401 if old password is incorrect."
add_link 7 "PUT" "/user/password" "401" "07_change_password_wrong.md"

# === 8. Login with new password ===
step 8 "POST /auth/login - password"
BODY='{"phone":"'$PHONE'","type":"password","credential":"newpass789"}'
RESP=$(curl -s -X POST "$BASE/auth/login" -H "Content-Type: application/json" -d "$BODY")
[ -z "$(json_val "$RESP" "token")" ] && fail "password login failed"
echo "user_id: $(json_num "$RESP" "user_id"), has_password: $(json_bool "$RESP" "has_password")"
pass
CURL="curl -s -X POST \"$BASE/auth/login\" \\
  -H \"Content-Type: application/json\" \\
  -d '$BODY'"
write_doc "08_login_password.md" "POST" "/auth/login" "Login with password." "$BODY" "200" "$RESP" "$CURL"
add_link 8 "POST" "/auth/login" "200" "08_login_password.md"

# === Write 00_link.md ===
echo -e "$LINK" > "$DOCS_DIR/00_link.md"

echo ""
echo "Generated: 00_link.md + 8 api docs"
echo ""
echo "========================================"
echo "  ALL $PASS STEPS PASSED"
echo "========================================"
