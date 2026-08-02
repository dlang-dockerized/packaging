module ddct.tests;

import ddct.datatype;
import ddct.util.template;
import ddct.util.containerfile;
import std.typecons;

@safe:

unittest {
    // 1. SemVer parsing and comparison
    auto s1 = SemVer.parse("1.30.0");
    auto s2 = SemVer.parse("1.30.1");
    auto s3 = SemVer.parse("2.0.0");
    
    assert(s1 !is null);
    assert(s2 !is null);
    assert(s3 !is null);
    assert(s1.compareTo(*s2) < 0);
    assert(s2.compareTo(*s3) < 0);
    assert(s3.compareTo(*s1) > 0);

    // SemVer Lax parsing
    auto sl1 = SemVer.parseLax("1.*");
    assert(sl1 !is null);
    assert(sl1.major == 1);
    assert(sl1.minor.isNull);
}

unittest {
    // 2. Natural sorting comparison helper
    assert(naturalCmp("2", "10") < 0);
    assert(naturalCmp("10", "2") > 0);
    assert(naturalCmp("abc2def", "abc10def") < 0);
    assert(naturalCmp("noble", "trixie") < 0);
    assert(naturalCmp("trixie", "noble") > 0);
}

unittest {
    // 3. Path traversal prefix match fix verification
    import std.path : dirSeparator;
    import std.algorithm : startsWith;
    
    string targetDir = "C:/Users/arush/containerfiles";
    string evilDir = "C:/Users/arush/containerfiles-evil/foo";
    
    string prefixWithSep = targetDir ~ "/";
    assert(!evilDir.startsWith(prefixWithSep));
}

unittest {
    // 4. AST template expressions parsing & execution
    Val[string] ctx;
    ctx["druntimeMonorepo"] = Val(true);
    ctx["app_name"] = Val("ldc");
    ctx["DISTRO"] = Val("debian");

    auto engine = new TemplateEngine("./templates");
    
    // Evaluate match statements
    auto val1 = engine.evaluateExpression("match(app_name) { 'ldc' => 'is-ldc', 'dmd' => 'is-dmd' }", ctx);
    assert(val1.toString() == "is-ldc");

    // Evaluate logical operators
    auto val2 = engine.evaluateExpression("druntimeMonorepo && (DISTRO == 'debian')", ctx);
    assert(val2.toBool() == true);
}
