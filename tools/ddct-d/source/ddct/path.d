module ddct.path;

@safe:

struct Path {
    static immutable string definitionsDir = "./definitions";
    static immutable string baseImageDefinitionsFile = "./definitions/baseimages.ini";
    static immutable string containerFileDefinitionsFile = "./definitions/containerfiles.ini";
    static immutable string containerFilesOutputDir = "./containerfiles";
    static immutable string templatesDir = "./templates";
}
