# Project Context

## Reference Project

`nurimAppDemo` is the previous hybrid demo:

- Repository: https://github.com/dkdrsmlee-dev/nurimAppDemo.git
- Structure: Flutter WebView shell plus React UI
- Flutter responsibilities: WebView host, JWT storage bridge, Kakao SDK, Naver native channel, deep links
- React responsibilities: splash, onboarding, social login start, terms, verification mock, profile input, signup complete, home, app state, API calls

## New Direction

`new_petnurim_app` should become a Flutter-first app.

- Rebuild app-owned screens as Flutter widgets.
- Reuse `nurimAppDemo` as a behavior and API reference, not as a codebase to embed wholesale.
- Keep WebView only where an external web flow is required.
- Move bridge concepts such as bootstrap/saveToken/clearToken into Flutter services.

## Candidate WebView Areas

- Daum/Kakao address search.
- PASS or identity verification only if the provider requires a web flow.
- Rich HTML terms content only if Flutter text rendering is insufficient.

## Early API Surface To Port

- `GET /api/v1/auth/config`
- `POST /api/v1/auth/social/{provider}`
- `GET /api/v1/terms`
- `POST /api/v1/auth/signup/terms`
- `POST /api/v1/auth/signup/verify-phone`
- `GET /api/v1/auth/signup/profile-init`
- `PATCH /api/v1/auth/signup/profile`
- `POST /api/v1/auth/signup/complete`

## Suggested Implementation Order

1. App shell, routing, state, and token storage.
2. API client and response envelope handling.
3. Kakao/Naver login and backend social login.
4. Signup flow screens and services.
5. Narrow WebView flows for address search or verification.
6. Home, bottom navigation, logout, and profile entry points.
