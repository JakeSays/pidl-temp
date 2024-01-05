
class GeneratorOptions
{
    String? defaultChannelName;
    bool forceChannelOverride;
    String? dartOutputRoot;
    String? cxxOutputRoot;
    bool forceGeneration;

    GeneratorOptions({
        this.dartOutputRoot,
        this.cxxOutputRoot,
        this.defaultChannelName,
        this.forceChannelOverride = false,
        this.forceGeneration = false
    });
}