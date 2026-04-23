package com.project.codebasespringjpa.repository;

import com.project.codebasespringjpa.entity.MajorEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;

@Repository
public interface IMajorRepository extends JpaRepository<MajorEntity, Long> {
    MajorEntity findByName(String name);
    List<MajorEntity> findByNameIn(Collection<String> names);
}
