package com.project.codebasespringjpa.mapper;

import com.project.codebasespringjpa.dto.course.request.CourseRequest;
import com.project.codebasespringjpa.dto.course.response.CourseDetailResponse;
import com.project.codebasespringjpa.dto.course.response.CourseResponse;
import com.project.codebasespringjpa.entity.CourseDetailEntity;
import com.project.codebasespringjpa.entity.CourseEntity;
import com.project.codebasespringjpa.entity.ObjectEntity;
import com.project.codebasespringjpa.repository.IObjectRepository;
import com.project.codebasespringjpa.util.UtilConst;
import com.project.codebasespringjpa.util.UtilFile;
import lombok.AccessLevel;
import lombok.experimental.FieldDefaults;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import java.util.Collections;
import java.util.ArrayList;
import java.util.List;

@Slf4j
@Component
@FieldDefaults(level = AccessLevel.PRIVATE)
public class CourseMapper {
    @Autowired
    IObjectRepository objectRepository;
    @Autowired
    CourseDetailMapper courseDetailMapper;

    public CourseEntity toEntity(CourseRequest request) {
        List<ObjectEntity> objectEntities = new ArrayList<>();
        try {
            if (request != null && request.getObjects() != null) {
                List<ObjectEntity> objects = objectRepository.findByNameIn(request.getObjects());
                if (objects != null) {
                    objectEntities.addAll(objects);
                }
            }
        } catch (Exception e) {
            log.error("Loi convert object entity - course mapper: ", e.getMessage());
        }
        return CourseEntity.builder()
                .name(request.getName())
                .description(request.getDescription())
                .image(request.getImage())
                .objects(objectEntities)
                .build();
    }

    public CourseResponse toResponse(CourseEntity entity) {
        if (entity == null) {
            return null;
        }
        List<String> objects = new ArrayList<>();
        List<CourseDetailResponse> courseDetailResponses = new ArrayList<>();
        List<ObjectEntity> objectEntities = entity.getObjects() != null ? entity.getObjects() : Collections.emptyList();
        for (ObjectEntity object : objectEntities) {
            if (object != null) {
                objects.add(object.getName());
            }
        }
        List<CourseDetailEntity> details = entity.getCourseDetail() != null ? entity.getCourseDetail() : Collections.emptyList();
        for (CourseDetailEntity courseDetail : details) {
            if (courseDetail.getIsDelete() == false) {
                courseDetailResponses.add(courseDetailMapper.toResponse(courseDetail));
            }
        }
        String imageTmp = UtilConst.NO_IMAGE_DEFAULT;
        if (UtilFile.hasImage(entity.getImage()))
            imageTmp = entity.getImage();
        return CourseResponse.builder()
                .id(entity.getId())
                .name(entity.getName())
                .description(entity.getDescription())
                .duration(entity.getDuration())
                .image(imageTmp)
                .createDate(entity.getCreateDate().toLocalDate())
                .updateDate(entity.getUpdateDate().toLocalDate())
                .objects(objects)
                .courseDetail(courseDetailResponses)
                .build();
    }
}
