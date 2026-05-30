# Test Spec

Maps every gap between the current test suite and full feature coverage. Tests are grouped by layer
(unit → integration) and by class. Each entry names the test, the assertion, and why it matters.

---

## Unit tests

### `UserTest` (`test/models/user_test.rb`)

Already covered: email normalization, Argon2 hashing, successful and failed authentication.

**Missing:**

| Test name | Assertion | Why |
|---|---|---|
| `password too short fails validation` | `user.valid?` → false; errors on `:password` | Minimum 12 chars enforced |
| `blank password fails validation` | `user.valid?` → false; errors on `:password_digest` | Password digest cannot be blank |
| `invalid email format is rejected` | `user.valid?` → false; errors on `:email` | URI::MailTo regexp enforced |
| `duplicate email is rejected` | save second user with same email → false | Uniqueness constraint |
| `blank name fails validation` | `user.valid?` → false; errors on `:name` | Name presence required |
| `admin flag is false by default` | `User.new.admin?` → false | Non-admin users must not gain access |
| `authenticate returns false for blank password` | `user.authenticate("")` → false | Guard against empty string bypass |

---

### `PostTest` (`test/models/post_test.rb`)

Already covered: `visible` scope, slug from title, markdown XSS sanitization.

**Missing:**

| Test name | Assertion | Why |
|---|---|---|
| `title over 160 chars fails validation` | `post.valid?` → false; errors on `:title` | DB and display constraint |
| `blank title fails validation` | `post.valid?` → false; errors on `:title` | Presence required |
| `blank excerpt fails validation` | `post.valid?` → false; errors on `:excerpt` | Presence required |
| `excerpt over 500 chars fails validation` | `post.valid?` → false; errors on `:excerpt` | Length constraint |
| `blank body_markdown fails validation` | `post.valid?` → false; errors on `:body_markdown` | Presence required |
| `slug with invalid characters fails validation` | slug `"my post!"` → errors on `:slug` | Format: only `[a-z0-9-]` allowed |
| `slug over 180 chars fails validation` | `post.valid?` → false; errors on `:slug` | Length constraint |
| `duplicate slug fails validation` | save second post with same slug → false | Uniqueness constraint |
| `custom slug is preserved` | set `slug: "my-custom-slug"`, assert not overwritten | Slug only auto-fills from title when blank |
| `to_param returns slug` | `post.to_param` == `post.slug` | Routes use slug, not id |
| `published_at is set when status changes to published` | change status to published, assert `published_at` present | Auto-assign on publish |
| `published_at is cleared when post is moved back to draft` | change published post to draft, assert `published_at` nil | Draft posts have no publish date |
| `visible scope excludes future-published posts` | post with `published_at` = tomorrow not in `Post.visible` | Scheduled posts not leaked early |
| `recent_first orders by published_at descending` | two published posts, assert correct order | Homepage ordering |

---

### `JsonWebTokenTest` (`test/services/json_web_token_test.rb`)

Already covered: encode/decode round-trip, invalid token returns nil.

**Missing:**

| Test name | Assertion | Why |
|---|---|---|
| `expired token returns nil` | encode with past `expires_at`, decode → nil | Sessions must not survive past 12 hours |
| `token with wrong issuer returns nil` | hand-craft JWT with `iss: "other"`, decode → nil | Issuer verification enforced |
| `token signed with wrong secret returns nil` | sign with different secret, decode → nil | Token cannot be forged |
| `payload claims survive round-trip` | encode `{ sub: 42, role: "admin" }`, decode → same values | All claims preserved |

---

## Integration / controller tests

### `AdminSessionsControllerTest` (`test/controllers/admin_sessions_controller_test.rb`)

Already covered: page renders, already-authenticated redirect, valid login, wrong password, non-admin
rejection, logout redirect.

**Missing:**

| Test name | Assertion | Why |
|---|---|---|
| `login sets an HTTP-only encrypted cookie` | after POST, `cookies[:admin_token]` present; response has `HttpOnly` in Set-Cookie | Cookie security properties must be verified |
| `after logout admin posts redirect to login` | sign in → logout → `GET /admin/posts` → redirect to `superadmin_login_path` | Confirms cookie is actually cleared |
| `sign in with blank email returns 422` | POST with `email: ""` → `:unprocessable_entity` | No ambiguous error from nil lookup |
| `sign in with non-existent email returns 422` | POST with unknown email → `:unprocessable_entity` | Same response regardless of whether user exists |

---

### `AdminPostsControllerTest` (`test/controllers/admin_posts_controller_test.rb`)

Already covered: anonymous redirect, list all posts, create draft.

**Missing:**

| Test name | Assertion | Why |
|---|---|---|
| `admin can view a single post` | `GET /admin/posts/:slug` → 200 | Show action not tested |
| `admin can reach the edit form` | `GET /admin/posts/:slug/edit` → 200 | Edit action not tested |
| `admin can update a post` | `PATCH /admin/posts/:slug` with new title → redirect; title persisted | Update action not tested |
| `update with invalid params returns 422` | PATCH with blank title → `:unprocessable_entity` | Validation errors render form |
| `admin can delete a post` | `DELETE /admin/posts/:slug` → redirect; `Post.count` decreases by 1 | Destroy action not tested |
| `admin can publish a draft post` | PATCH status `published` → `published_at` set on record | Business rule: auto-assign publish date |
| `publishing a post sets published_at to now` | PATCH status `published`; `post.reload.published_at` within last 5 seconds | Timestamp correctness |
| `admin can create a post with a custom slug` | POST with explicit `slug:` → record saved with that slug | Custom slug is not overwritten |
| `post creation with missing title returns 422` | POST with blank title → `:unprocessable_entity` | Validation errors bubble correctly |
| `non-admin user is redirected to login` | sign in as non-admin (forge cookie) → redirect to login | `admin?` flag checked, not just authentication |
| `expired JWT cookie redirects to login` | set manually expired token cookie → `GET /admin/posts` → redirect | Token expiry enforced at request time |
| `anonymous user redirected from new post form` | `GET /admin/posts/new` → redirect to `superadmin_login_path` | New action also protected |
| `anonymous user redirected from edit form` | `GET /admin/posts/:slug/edit` → redirect to `superadmin_login_path` | Edit action also protected |

---

### `AdminImagesControllerTest` (`test/controllers/admin_images_controller_test.rb`)

Already covered: anonymous redirect (broken — still points to old path), upload PNG, unsupported MIME type.

**Missing / broken:**

| Test name | Assertion | Why |
|---|---|---|
| `anonymous redirect goes to superadmin_login_path` | fix existing assertion from `new_admin_session_path` to `superadmin_login_path` | Path changed in this feature branch |
| `oversized file is rejected` | upload file > 5 MB → `:unprocessable_entity` | Size validation not tested |
| `upload returns markdown snippet with proxied URL` | response JSON `markdown` contains `/rails/active_storage/` | Active Storage proxy confirmed, not direct MinIO URL |

---

### `PostsControllerTest` (`test/controllers/posts_controller_test.rb`)

Already covered: list published, show published, draft returns 404.

**Missing:**

| Test name | Assertion | Why |
|---|---|---|
| `future-published post is not listed publicly` | post with `published_at` = tomorrow not in index response | Scheduled posts must not leak |
| `future-published post returns 404` | `GET /posts/:slug` for future post → `:not_found` | Consistent with listing behaviour |
| `non-existent slug returns 404` | `GET /posts/does-not-exist` → `:not_found` | No unhandled RecordNotFound |
| `public layout contains no admin link` | index response body does not match `/admin|superadmin/` | Spec requirement: no hints in public pages |
| `pagination shows six posts per page` | create 7 published posts; index lists 6; page 2 lists 1 | Pagination boundary condition |
| `rendered markdown is present in show` | show response body contains expected HTML (e.g. `<strong>`) | Markdown is rendered server-side |

---

## Implementation order

1. Fix the broken `AdminImagesControllerTest` redirect assertion first (it fails today).
2. Unit tests — they run fast and surface model/service bugs before integration tests run.
3. Integration tests for sessions (auth foundation everything else depends on).
4. Integration tests for admin posts (largest surface area).
5. Integration tests for public posts (regression safety net).
