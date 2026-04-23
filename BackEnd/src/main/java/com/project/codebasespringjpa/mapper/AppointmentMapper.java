package com.project.codebasespringjpa.mapper;

import com.project.codebasespringjpa.dto.appointment.request.AppointmentRequest;
import com.project.codebasespringjpa.dto.appointment.response.AppointmentResponse;
import com.project.codebasespringjpa.entity.AppointmentEntity;
import com.project.codebasespringjpa.entity.UserEntity;
import com.project.codebasespringjpa.exception.AppException;
import com.project.codebasespringjpa.exception.ErrorCode;
import com.project.codebasespringjpa.repository.IUserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class AppointmentMapper {
    @Autowired
    IUserRepository userRepository;

    public AppointmentEntity toEntity(AppointmentRequest request) {
        UserEntity userEntity = userRepository.findByUsername(request.getUsername())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));
        UserEntity specialEntity = userRepository.findByUsername(request.getSpecialistName())
                .orElseThrow(() -> new AppException(ErrorCode.USER_NOT_FOUND));
        return AppointmentEntity.builder()
                .userId(userEntity.getId())
                .username(request.getUsername())
                .specialistId(specialEntity.getId())
                .specialistName(request.getSpecialistName())
                .date(request.getDate())
                .hours(request.getHours())
                .duration(request.getDuration())
                .status(request.getStatus())
                .build();
    }

    public AppointmentResponse toResponse(AppointmentEntity entity) {
        if (entity == null) {
            return null;
        }
        return AppointmentResponse.builder()
                .id(entity.getId())
                .userId(entity.getUserId())
                .userName(entity.getUsername())
                .userFullName(entity.getUserFullName())
                .specialistId(entity.getSpecialistId())
                .specialistName(entity.getSpecialistName())
                .specialistFullname(entity.getSpecialistFullName())
                .date(entity.getDate())
                .hours(entity.getHours())
                .duration(entity.getDuration())
                .status(entity.getStatus())
                .build();
    }
}
