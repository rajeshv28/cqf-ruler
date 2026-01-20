FROM eclipse-temurin:21-jdk-jammy AS build
WORKDIR /src
COPY . .

# Very important: pull submodules if repo uses them
# (works even if no submodules exist)
RUN git submodule update --init --recursive || true

RUN ./mvnw -B -DskipTests clean package

FROM eclipse-temurin:21-jre-jammy
WORKDIR /app

# NOTE: This is a placeholder. We will adjust after we confirm the right jar/war.
# For now we copy everything and print artifacts during first run.
COPY --from=build /src /src

EXPOSE 8080
CMD ["bash","-lc","find /src -name '*.jar' -o -name '*.war' | sed -n '1,80p' && echo 'Container built. Update CMD to run the correct jar/war.' && sleep infinity"]
