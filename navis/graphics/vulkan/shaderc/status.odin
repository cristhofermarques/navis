package shaderc

Compilation_Status :: enum
{
    Success = 0,
    Invalid_Stage = 1,
    Compilation_Error = 2,
    Internal_Error = 3,
    Null_Result_Object = 4,
    Invalid_Assembly = 5,
    Validation_Error = 6,
    Transformation_Error = 7,
    Configuration_Error = 8,
}