# =========================
# Build stage
# =========================
FROM public.ecr.aws/amazoncorretto/amazoncorretto:21 AS build

WORKDIR /src
COPY . .

# If submodules exist, fetch them; if none, do nothing
RUN chmod +x mvnw
RUN git submodule update --init --recursive || true

# Build only the modules we need (skip external because it fails)
RUN ./mvnw -B -DskipTests -pl ./core,./plugin,./server clean package
RUN echo 'Built artifacts:' && ls -la /src/server/target

# =========================
# Runtime stage
# =========================
FROM public.ecr.aws/amazoncorretto/amazoncorretto:21
WORKDIR /app

COPY --from=build /src/server/target /app/target

EXPOSE 8080

CMD ["bash","-lc", "\
   set -euo pipefail; \
   echo 'Listing /app/target:'; \
   ls -la /app/target || true; \
   echo 'Looking for runnable WAR or JAR in /app/target...'; \
   echo 'All wars found:'; \
   ls -1 /app/target/*.war 2>/dev/null || true; \
   echo 'All jars found:'; \
   ls -1 /app/target/*.jar 2>/dev/null || true; \
   WAR=$(ls -1 /app/target/*.war 2>/dev/null | grep -vE '\\.original$' | head -n 1 || true); \
   if [ -n \"${WAR:-}\" ]; then \
   echo \"Starting WAR: $WAR\"; \
   exec java -XX:MaxRAMPercentage=75 -jar \"$WAR\"; \
   fi; \
   JAR=$(ls -1 /app/target/*.jar 2>/dev/null | grep -vE '(sources|javadoc|original|plain)\\.jar$' | head -n 1 || true); \
   if [ -n \"${JAR:-}\" ]; then \
   echo \"Starting JAR: $JAR\"; \
   exec java -XX:MaxRAMPercentage=75 -jar \"$JAR\"; \
   fi; \
   echo 'ERROR: No runnable WAR or JAR found in /app/target.'; \
   exit 1 \
   "]
