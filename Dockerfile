# ---- Build stage ----
FROM public.ecr.aws/amazoncorretto/amazoncorretto:21 AS build
WORKDIR /src
COPY . .

# pull submodules if present (won't fail if none)
RUN git submodule update --init --recursive || true

# 1) Print modules so we can see correct names in CodeBuild logs
# 2) Build ONLY the server module (we will set MODULE after we discover it)
ARG MODULE=""
RUN echo "===== LISTING MODULES (pom.xml) =====" && (grep -n "<module>" pom.xml || true)

# If MODULE is not set, fail with a clear message
RUN if [ -z "$MODULE" ]; then echo "ERROR: MODULE build-arg not set. Set MODULE to the runnable server module name." && exit 1; fi

# Build only the chosen module + its dependencies
# RUN ./mvnw -B -DskipTests -pl "./$MODULE" -am clean package
RUN ./mvnw -B -DskipTests -pl ./server -am clean package


# ---- Runtime stage ----
FROM public.ecr.aws/amazoncorretto/amazoncorretto:21
WORKDIR /app

# Copy only built artifacts directory tree (keeps image smaller than copying entire source)
COPY --from=build /src /src

EXPOSE 8080

# Temporary: show jars so we can pick the runnable one; then keep container alive
CMD ["bash","-lc","find /src -name '*.jar' -o -name '*.war' | sed -n '1,120p' && echo 'Image ready. Next: set CMD to java -jar <the runnable jar>.' && sleep infinity"]
