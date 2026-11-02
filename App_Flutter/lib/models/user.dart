import 'dart:convert';

User userFromJson(String str) => User.fromJson(json.decode(str));
String userToJson(User data) => json.encode(data.toJson());

List<User> usersFromJson(String str) => List<User>.from(json.decode(str).map((x) => User.fromJson(x)));
String usersToJson(List<User> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class User {
  String organization;
  String userId;
  String email;
  Token token;
  List<Role> roles;

  User({required this.organization, required this.userId, required this.email, required this.token, required this.roles});

  factory User.fromJson(Map<String, dynamic> json) => User(
        organization: json["user"]["organization"],
        userId: json["user"]["userId"],
        email: json["user"]["email"],
        token: Token(accessToken: json['accessToken'], expiresIn: json['expiresIn']),
        roles: List<Role>.from((json["user"]["roles"]).map(
                (roleJson) => Role.fromJson(roleJson as Map<String, dynamic>)
        )),
      );

  Map<String, dynamic> toJson() => {
        "organization": organization,
        "userId": userId,
        "email": email,
        'roles': roles.map((e) => e.toJson()).toList(),
      };
}

Token tokenFromJson(String str) => Token.fromJson(json.decode(str));
String tokenToJson(Token data) => json.encode(data.toJson());

class Token {
  int expiresIn;
  String accessToken;

  Token({
    required this.accessToken,
    required this.expiresIn,
  });

  factory Token.fromJson(Map<String, dynamic> json) => Token(
        accessToken: json["accessToken"],
        expiresIn: json["expiresIn"],
      );

  Map<String, dynamic> toJson() => {
        "accessToken": accessToken,
        "expiresIn": expiresIn,
      };
}

class Role {
  int roleId;
  String name;

  Role({
    required this.roleId,
    required this.name,
  });

  factory Role.fromJson(Map<String, dynamic> json) => Role(
        roleId: json['roleId'] as int,  // Explicit cast to int
        name: json['name'] as String,    // Explicit cast to String
      );

  Map<String, dynamic> toJson() => {
        "roleId": roleId,
        "name": name,
      };
}
