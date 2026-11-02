package precious_weight.auth.models.request;

public class UserRequest {
        private String email;
        private String password;
        private String organization;

        public UserRequest() {}

        public UserRequest(String email, String password, String organization) {
            this.email = email;
            this.password = password;
            this.organization = organization;
        }

        // Getters and setters
        public String getEmail() {
            return email;
        }
        public void setEmail(String email) {
            this.email = email;
        }

        public String getPassword() {
            return password;
        }
        public void setPassword(String password) {
            this.password = password;
        }

        public String getOrganization() { return organization; }
        public void setOrganization(String organization) {
            this.organization = organization;
        }

}
