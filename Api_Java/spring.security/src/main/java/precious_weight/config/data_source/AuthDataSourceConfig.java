package precious_weight.config.data_source;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.jdbc.DataSourceBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.orm.jpa.JpaTransactionManager;
import org.springframework.orm.jpa.LocalContainerEntityManagerFactoryBean;
import org.springframework.orm.jpa.vendor.HibernateJpaVendorAdapter;
import org.springframework.transaction.PlatformTransactionManager;

import javax.sql.DataSource;
import java.util.HashMap;
import java.util.Map;

@Configuration
@EnableJpaRepositories(
        basePackages = "precious_weight.auth",
        entityManagerFactoryRef = "authEntityManagerFactory",
        transactionManagerRef = "authTransactionManager"
)
public class AuthDataSourceConfig {

    @Bean
    @ConfigurationProperties(prefix="spring.auth.datasource")
    public DataSource authDataSource() {
        return DataSourceBuilder.create().build();
    }

    @Bean
    public LocalContainerEntityManagerFactoryBean authEntityManagerFactory() {
        LocalContainerEntityManagerFactoryBean em = new LocalContainerEntityManagerFactoryBean();
        em.setDataSource(authDataSource());
        em.setPackagesToScan(
                "precious_weight.auth.models",
                "precious_weight.auth.models.request",
                "precious_weight.auth.models.response"
        );
        em.setPersistenceUnitName("auth");

        HibernateJpaVendorAdapter vendorAdapter = new HibernateJpaVendorAdapter();
        em.setJpaVendorAdapter(vendorAdapter);

        Map<String, Object> jpaProperties = new HashMap<>();
        //jpaProperties.put("hibernate.hbm2ddl.auto", "create"); //Apaga tudo e cria do zero a cada vez que inicia
        //jpaProperties.put("hibernate.hbm2ddl.auto", "validate"); //Apenas verifica se as tabelas/campos batem com as entidades
        jpaProperties.put("hibernate.hbm2ddl.auto", "update"); //Cria ou altera tabelas e colunas sem apagar dados
        jpaProperties.put("hibernate.dialect", "org.hibernate.dialect.MySQL8Dialect");
        em.setJpaPropertyMap(jpaProperties);

        return em;
    }

    @Bean
    public PlatformTransactionManager authTransactionManager() {
        JpaTransactionManager transactionManager = new JpaTransactionManager();
        transactionManager.setEntityManagerFactory(authEntityManagerFactory().getObject());
        return transactionManager;
    }
}