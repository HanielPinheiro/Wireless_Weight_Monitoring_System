package precious_weight.auth.models;

import jakarta.persistence.*;

import static precious_weight.config.system.DataTransferLayerConstants.Auth_RoleTable_TableName;
import static precious_weight.config.system.DataTransferLayerConstants.Auth_RoleTable_Id;
import static precious_weight.config.system.DataTransferLayerConstants.Auth_RoleTable_Name;

@Entity
@Table(name = Auth_RoleTable_TableName)
public class RoleModel {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = Auth_RoleTable_Id)
    private Long roleId;

    @Column(name = Auth_RoleTable_Name)
    private String name;

    public Long getRoleId() {
        return roleId;
    }
    public void setRoleId(Long roleId) {
        this.roleId = roleId;
    }

    public String getName() {
        return name;
    }
    public void setName(String name) {
        this.name = name;
    }

    public enum Values{
        ADMIN(1L),
        BASIC(2L);

        final long roleId;
        Values(long roleId){
            this.roleId = roleId;
        }
        public long getRoleId() {
            return roleId;
        }
    }

    @Override
    public String toString() {
        return "RoleModel{ roleId=" + roleId +", name='" + name + '\'' +'}';
    }
}
