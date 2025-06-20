# Multi-stage build for optimized image
FROM openjdk:11-jdk-slim as build

# Set working directory
WORKDIR /app

# Copy Maven files
COPY pom.xml .
COPY src ./src

# Install Maven
RUN apt-get update && apt-get install -y maven

# Build the application
RUN mvn clean package -DskipTests

# Production stage
FROM openjdk:11-jre-slim

# Set working directory
WORKDIR /app

# Copy the built JAR from build stage
COPY --from=build /app/target/task-manager-api-1.0.0.jar app.jar

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/api/tasks/health || exit 1

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
