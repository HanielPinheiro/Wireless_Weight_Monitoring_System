package precious_weight.app.models.envers;

import org.hibernate.envers.AuditReader;
import org.hibernate.envers.AuditReaderFactory;
import org.hibernate.envers.query.AuditEntity;

import org.springframework.stereotype.Repository;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

import precious_weight.app.models.ScaleModel;
import precious_weight.app.models.BabyModel;
import precious_weight.app.models.WeightModel;

import java.util.List;

@Repository
public class AuditRepository {

    @PersistenceContext
    private EntityManager entityManager;

    public List<Object[]> getBabyRevisions(Integer babyId) {
        AuditReader auditReader = AuditReaderFactory.get(entityManager);
        return auditReader.createQuery()
                .forRevisionsOfEntity(BabyModel.class, false, true)
                .add(AuditEntity.id().eq(babyId))
                .getResultList();
    }

    public List<Object[]> getScaleRevisions(Integer scaleId) {
        AuditReader auditReader = AuditReaderFactory.get(entityManager);
        return auditReader.createQuery()
                .forRevisionsOfEntity(ScaleModel.class, false, true)
                .add(AuditEntity.id().eq(scaleId))
                .getResultList();
    }

    public List<Object[]> getWeightRevisions(Integer babyId) {
        AuditReader auditReader = AuditReaderFactory.get(entityManager);
        return auditReader.createQuery()
                .forRevisionsOfEntity(WeightModel.class, false, true)
                .add(AuditEntity.property("babyId").eq(babyId))
                .getResultList();
    }
}
