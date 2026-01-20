# ---- Build stage ----
FROM public.ecr.aws/amazoncorretto/amazoncorretto:21 AS build
WORKDIR /src
COPY . .

# If submodules exist, fetch them; if not, this won't fail the build
RUN git submodule update --init --recursive || true

RUN ./mvnw -B -DskipTests clean package

# ---- Runtime stage ----
FROM public.ecr.aws/amazoncorretto/amazoncorretto:21
WORKDIR /app

COPY --from=build /src /src

EXPOSE 8080
CMD ["bash","-lc","find /src -name '*.jar' -o -name '*.war' | sed -n '1,80p' && echo 'Update CMD to run the correct artifact.' && sleep infinity"]
