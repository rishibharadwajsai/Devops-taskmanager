package com.taskmanager.service;

import com.taskmanager.model.Task;
import com.taskmanager.repository.TaskRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class TaskServiceTest {

    @Mock
    private TaskRepository taskRepository;

    @InjectMocks
    private TaskService taskService;

    private Task task;

    @BeforeEach
    void setUp() {
        task = new Task("Test Task", "Test Description");
        task.setId(1L);
    }

    @Test
    public void testGetAllTasks() {
        when(taskRepository.findAll()).thenReturn(Arrays.asList(task));

        List<Task> tasks = taskService.getAllTasks();

        assertEquals(1, tasks.size());
        assertEquals("Test Task", tasks.get(0).getTitle());
    }

    @Test
    public void testGetTaskById() {
        when(taskRepository.findById(1L)).thenReturn(Optional.of(task));

        Optional<Task> foundTask = taskService.getTaskById(1L);

        assertTrue(foundTask.isPresent());
        assertEquals("Test Task", foundTask.get().getTitle());
    }

    @Test
    public void testCreateTask() {
        when(taskRepository.save(any(Task.class))).thenReturn(task);

        Task createdTask = taskService.createTask(task);

        assertEquals("Test Task", createdTask.getTitle());
        verify(taskRepository, times(1)).save(task);
    }

    @Test
    public void testDeleteTask() {
        taskService.deleteTask(1L);
        verify(taskRepository, times(1)).deleteById(1L);
    }
}
