class MethodStatus
{
    static const int Unknown = 0;
    static const int Success = 1;
    static const int SuccessWithReply = 2;
    static const int Error = 3;

    static String name(int value)
    {
        switch(value)
        {
            case Success:
                return "Success";
            case SuccessWithReply:
                return "SuccessWithReply";
            case Error:
                return "Error";
            default:
                return "Unknown";
        }
    }
}