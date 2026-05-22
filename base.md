Based on the validation results, I'll now compile the final security review report with only high-confidence findings (score ≥8).

# Security Review Report

## Vuln 1: CSRF Protection Bypass - Token Generation Without Validation

**File:** `src/main/java/com/capital/base/support/CsrfCookieSupport.java:13-26`  
**Severity:** HIGH  
**Category:** csrf_bypass  
**Confidence:** 9/10

**Description:**  
The application generates CSRF tokens and sets them as `XSRF-TOKEN` cookies after successful login, but there is no corresponding validation logic anywhere in the codebase that checks the `X-XSRF-TOKEN` header on state-changing requests. This is an incomplete implementation of the double-submit cookie pattern - the token is generated and sent to the client, but the server never validates it.

**Exploit Scenario:**  
1. Victim user authenticates and receives both a session cookie (Sa-Token) and CSRF cookie
2. Attacker tricks victim into visiting a malicious website while authenticated
3. Malicious site makes POST requests to state-changing endpoints like `/api/system-user/delete`, `/api/role/delete`, `/api/org/update`
4. Browser automatically includes the session cookie (SameSite=Lax allows POST from top-level navigation)
5. Server validates session but never checks CSRF token, allowing the request to succeed
6. Attacker can perform arbitrary authenticated actions: create/delete users, modify roles, change organization data

**Recommendation:**  
Implement CSRF token validation by creating a filter that:
1. Reads the `X-XSRF-TOKEN` header from incoming requests
2. Reads the `XSRF-TOKEN` cookie value
3. Compares them for equality on all state-changing requests (POST, PUT, DELETE, PATCH)
4. Rejects requests where they don't match with 403 Forbidden

Example filter implementation:
```java
@Component
public class CsrfValidationFilter extends OncePerRequestFilter {
    @Override
    protected void doFilterInternal(HttpServletRequest request, 
                                   HttpServletResponse response, 
                                   FilterChain chain) throws ServletException, IOException {
        if (isStateChanging(request.getMethod())) {
            String headerToken = request.getHeader("X-XSRF-TOKEN");
            String cookieToken = getCookieValue(request, "XSRF-TOKEN");
            
            if (headerToken == null || !headerToken.equals(cookieToken)) {
                response.setStatus(403);
                response.getWriter().write("{\"status\":403,\"msg\":\"CSRF token validation failed\"}");
                return;
            }
        }
        chain.doFilter(request, response);
    }
}
```

---

## Vuln 2: Authentication Rate Limiting Bypass via IP Spoofing

**File:** `src/main/java/com/capital/base/security/AuthRateLimitFilter.java:53`  
**Severity:** HIGH  
**Category:** auth_bypass  
**Confidence:** 8/10

**Description:**  
The authentication rate limiting filter uses `TrustedProxyClientIpResolver.resolve(request)` to extract the client IP address for rate limiting purposes. This class is imported from an external dependency (`com.capital.common.util`) and its implementation is not visible in this codebase. No configuration exists for trusted proxy IP addresses in any of the application configuration files (dev, test, prod). Without proper validation of proxy headers, an attacker can spoof the `X-Forwarded-For` header to bypass rate limiting entirely.

**Exploit Scenario:**  
1. Attacker targets authentication endpoints: `/api/auth/login-token`, `/api/auth/org-login-token`, `/api/org/portal-link/verify`
2. Rate limiting is configured to allow 10 requests per 60 seconds per IP
3. Attacker sends requests with spoofed `X-Forwarded-For` headers:
   - Request 1: `X-Forwarded-For: 1.1.1.1`
   - Request 2: `X-Forwarded-For: 1.1.1.2`
   - Request 3: `X-Forwarded-For: 1.1.1.3`
   - ... (unlimited requests)
4. Each request appears to come from a different IP address
5. Redis rate limiting keys (`auth:rl:/api/auth/login-token:1.1.1.1`, etc.) never reach the limit
6. Attacker performs unlimited brute-force attacks against user credentials and organization codes

**Recommendation:**  
1. **Immediate fix:** If the application is not behind a proxy, use `request.getRemoteAddr()` directly instead of trusting proxy headers
2. **If behind a proxy:** Configure a whitelist of trusted proxy IP addresses and validate that `X-Forwarded-For` headers only come from trusted sources
3. **Add configuration** for trusted proxies in `application.yml`:
```yaml
auth:
  rate-limit:
    trusted-proxies:
      - 10.0.0.0/8
      - 172.16.0.0/12
```
4. **Implement validation** in the IP resolver to reject spoofed headers from untrusted sources

---

## Vuln 3: Unauthenticated Session Validation Oracle

**File:** `src/main/java/com/capital/base/controller/AuthController.java:50-53`  
**Severity:** MEDIUM  
**Category:** info_disclosure  
**Confidence:** 8/10

**Description:**  
The new `/api/auth/session` GET endpoint lacks any authentication annotation (`@SaCheckLogin` or `@SaCheckPermission`). No global authentication interceptor exists in the codebase, meaning endpoints without explicit annotations are publicly accessible. While the service method checks `StpUtil.isLogin()` internally, this service-level check is insufficient - the endpoint itself is accessible without authentication and returns different responses based on token validity, creating a token validation oracle.

**Exploit Scenario:**  
1. Attacker obtains potential session tokens through various means (leaked logs, network sniffing, social engineering)
2. Attacker calls `GET /api/auth/session` with each token
3. For valid tokens: receives `200 OK` with `{"status":200, "data":{"loginId":"123", "username":"admin"}}`
4. For invalid tokens: receives `401 Unauthorized` with `{"status":401, "msg":"未登录"}`
5. Attacker can validate stolen tokens without triggering login attempt logs or rate limiting
6. Attacker identifies which tokens are still active and can be used for session hijacking
7. Leaked `loginId` and `username` provide additional reconnaissance information

**Recommendation:**  
Add authentication requirement to the endpoint:
```java
@SaCheckLogin  // Require valid authentication
@GetMapping("/session")
public ResultModel session() {
    return authService.session();
}
```

If the endpoint must remain public for frontend route guards, redesign it to not leak token validity information - return a generic response that doesn't distinguish between valid and invalid tokens.
