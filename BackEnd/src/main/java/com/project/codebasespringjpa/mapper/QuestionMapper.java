package com.project.codebasespringjpa.mapper;

import com.project.codebasespringjpa.dto.answer.response.AnswerResponse;
import com.project.codebasespringjpa.dto.question.response.QuestionResponse;
import com.project.codebasespringjpa.entity.AnswerEntity;
import com.project.codebasespringjpa.entity.QuestionEntity;
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
public class QuestionMapper {
    @Autowired
    AnswerMapper answerMapper;

    public QuestionResponse toResponse(QuestionEntity entity){
        if (entity == null) {
            return null;
        }
        List<AnswerResponse>answerResponses = new ArrayList<>();
        List<AnswerEntity> answers = entity.getAnswers() != null ? entity.getAnswers() : Collections.emptyList();
        for (AnswerEntity answer: answers){
            answerResponses.add(answerMapper.toResponse(answer));
        }
        return QuestionResponse.builder()
                .id(entity.getId())
                .content(entity.getContent())
                .answers(answerResponses)
                .build();
    }
}
