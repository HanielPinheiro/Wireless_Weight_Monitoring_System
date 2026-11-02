package precious_weight.config.system;

public class DataTransferLayerConstants {

    public static final String App_BabyTable_TableName = "babies";
    public static final String App_BabyTable_Id = "baby_id";
    public static final String App_BabyTable_HospitalId = "baby_hospital_id";
    public static final String App_BabyTable_Image = "baby_image";
    public static final String App_BabyTable_ImageText = "baby_image_text";
    public static final String App_BabyTable_Name = "baby_name";
    public static final String App_BabyTable_MotherName = "baby_mother_name";
    public static final String App_BabyTable_BirthDate = "baby_birthdate";
    public static final String App_BabyTable_State = "baby_state";
    public static final String App_BabyTable_WeightHour = "baby_weight_hour";

    public static final String App_ScaleTable_TableName = "scales";
    public static final String App_ScaleTable_Id = "scale_id";
    public static final String App_ScaleTable_Hash = "scale_hash";
    public static final String App_ScaleTable_State = "scale_state";
    public static final String App_ScaleTable_IsConnected = "is_connected";
    public static final String App_ScaleTable_LastConnectedAt = "scale_last_connected_at";
    public static final String App_ScaleTable_LastDisconnectedAt = "scale_last_disconnected_at";
    public static final String App_ScaleTable_WifiStrength = "scale_last_wifi_strength";

    public static final String App_WeightTable_TableName = "weights";
    public static final String App_WeightTable_Id = "weight_id";
    public static final String App_WeightTable_Date = "weight_date";
    public static final String App_WeightTable_Value = "weight_value";

    public static final String App_WifiConnectivity_TableName = "wifi_connectivity";
    public static final String App_WifiConnectivity_Id = "wifi_connectivity_id";
    public static final String App_WifiConnectivity_Date = "wifi_connectivity_date";
    public static final String App_WifiConnectivity_Value = "wifi_connectivity_value";

    public static final String App_WifiStrengthTable_TableName = "wifi_strengths";
    public static final String App_WifiStrengthTable_Id = "wifi_strength_id";
    public static final String App_WifiStrengthTable_Date = "wifi_strength_date";
    public static final String App_WifiStrengthTable_Value = "wifi_strength_value";

    public static final String Auth_UserTable_TableName = "users";
    public static final String Auth_UserTable_Id = "user_id";
    public static final String Auth_UserTable_Email = "user_email";
    public static final String Auth_UserTable_Password = "user_password";
    public static final String Auth_UserTable_Organization = "user_org";

    public static final String Auth_UserRoleRel_TableName = "user_roles_rel";

    public static final String Auth_RoleTable_TableName = "roles";
    public static final String Auth_RoleTable_Id = "role_id";
    public static final String Auth_RoleTable_Name = "role_name";

    public static final String Auth_ScaleTable_TableName = "scales";
    public static final String Auth_ScaleTable_Id = "scale_id";
    public static final String Auth_ScaleTable_Mac = "scale_mac";
    public static final String Auth_ScaleTable_Pop = "scale_pop";
    public static final String Auth_ScaleTable_QrCode = "scale_qrcode";
}
