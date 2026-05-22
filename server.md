根据三步审查结果，过滤掉置信度 < 8 的漏洞（漏洞 3 置信度 6、漏洞 4 置信度 2、漏洞 5 置信度 6、漏洞 6 置信度 3），最终报告如下：

---

# 安全审查报告

## Vuln 1: 硬编码 PBKDF2 Salt：`AesKeyDeriver.java:124`

* **严重程度：** High
* **类别：** crypto_weak_key_derivation（CWE-760）
* **置信度：** 9/10

**描述：**
`AesKeyDeriver` 使用硬编码的固定 salt 值 `"capital-aes-kdf-v1"` 进行 PBKDF2-HMAC-SHA256 密钥派生。此 salt 作为静态常量在全应用范围内共享，违反了 NIST SP 800-132 和 OWASP 要求的"salt 必须随机生成且每次密钥派生唯一"原则。

```java
// AesKeyDeriver.java:124
private static final byte[] PBKDF2_SALT = "capital-aes-kdf-v1".getBytes(StandardCharsets.UTF_8);
```

此 salt 被 `deriveAes256KeyBytes`（库字段/报告 blob）和 `resolvePortalLinkAesKey`（门户 orgCode）两个关键加密路径共用。

**利用场景：**
1. 攻击者获得加密数据库备份或密文
2. 因 salt 已公开硬编码在源码中，攻击者可针对此固定 salt 离线预计算彩虹表
3. 使用预计算结果对常见弱口令（如 `admin123`、`capital@2024`）进行字典攻击
4. 一旦恢复派生密钥，即可解密所有受保护的机构代码和门户链接数据

**修复建议：**
应为每次密钥派生生成随机 salt，并与密文一同存储（salt 不需要保密）：
```java
// 加密时：生成随机 salt 并存储在密文前缀中
byte[] salt = new byte[32];
SecureRandom.getInstanceStrong().nextBytes(salt);
// 输出格式：version(1) || salt(32) || iv(16) || ciphertext

// 解密时：从密文前缀中读取 salt
byte[] salt = Arrays.copyOfRange(tokenBytes, 1, 33);
byte[] derivedKey = pbkdf2Sha256(passphrase, salt, iterations);
```

---

## Vuln 2: AES-CBC 缺少消息认证（Padding Oracle 攻击）：`AesCbcPortalLinkCodec.java:71`

* **严重程度：** High
* **类别：** crypto_missing_authentication（CWE-327）
* **置信度：** 9/10

**描述：**
`AesCbcPortalLinkCodec` 使用 `AES/CBC/PKCS5Padding` 加密但完全缺少消息认证码（MAC）。格式检查（版本号+长度）仅防止明显格式错误，无法验证密文完整性，导致攻击者可以提交篡改的密文并通过错误响应逐步推断明文。

```java
// AesCbcPortalLinkCodec.java:71-82
public static String decryptUtf8(byte[] aesKey, byte[] tokenBytes) {
    if (tokenBytes == null || tokenBytes.length < 1 + IV_LEN + 1
        || tokenBytes[0] != VERSION_RANDOM_IV) {
        throw new IllegalArgumentException("orgCode 格式无效或已过期，请重新获取门户链接");
    }
    try {
        byte[] plain = decryptV1(aesKey, tokenBytes);
        return new String(plain, java.nio.charset.StandardCharsets.UTF_8).trim();
    } catch (GeneralSecurityException e) {
        throw new IllegalArgumentException("orgCode 解密失败", e);  // 可区分于格式错误
    }
}
```

格式检查失败和解密失败（包括 padding 错误）返回不同的异常消息，攻击者可据此区分两种错误状态，满足 Padding Oracle 攻击的基本条件。

**利用场景：**
1. 攻击者截获合法的加密 orgCode token（来自门户链接 URL）
2. 修改密文最后一个块的任意字节，向服务器发送解密请求
3. 观察响应：格式错误（版本号/长度不符）vs 解密失败（padding 错误）可被区分
4. 通过 CBC 字节翻转原理，逐字节恢复每个块的明文，无需知道密钥
5. 完全恢复明文机构代码（orgCode），用于伪造门户访问令牌

**修复建议：**
将加密模式从 AES-CBC 迁移至 AES-GCM（认证加密，内置完整性保护）：
```java
// 推荐替换为 AES/GCM/NoPadding
private static final String TRANSFORMATION = "AES/GCM/NoPadding";
private static final int GCM_TAG_LEN = 128; // bits

private static byte[] cipher(byte[] aesKey, int mode, byte[] iv, byte[] input)
    throws GeneralSecurityException {
    Cipher c = Cipher.getInstance(TRANSFORMATION);
    GCMParameterSpec spec = new GCMParameterSpec(GCM_TAG_LEN, iv);
    c.init(mode, new SecretKeySpec(aesKey, "AES"), spec);
    return c.doFinal(input);
}
```
GCM 模式可同时提供加密和认证，任何篡改都会导致认证标签验证失败，彻底消除 Padding Oracle 和密文篡改风险。
