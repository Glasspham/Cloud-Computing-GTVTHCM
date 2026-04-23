package com.project.codebasespringjpa.repository;

import com.project.codebasespringjpa.entity.ObjectEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;

@Repository
public interface IObjectRepository extends JpaRepository<ObjectEntity, Long> {
    ObjectEntity findByName(String name);
    List<ObjectEntity> findByNameIn(Collection<String> names);
}
