idf_component_register(SRCS "mqtt3.c"
                     REQUIRES config
                        INCLUDE_DIRS ".")

target_add_binary_data(${COMPONENT_TARGET} "certs/client.crt" TEXT)
target_add_binary_data(${COMPONENT_TARGET} "certs/client.key" TEXT)
target_add_binary_data(${COMPONENT_TARGET} "certs/ca.crt" TEXT)

