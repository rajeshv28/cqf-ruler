FROM public.ecr.aws/temurin/temurin:21-jdk-jammy AS build
WORKDIR /src
COPY . .
RUN ./mvnw -B -DskipTests clean package

FROM public.ecr.aws/temurin/temurin:21-jre-jammy
WORKDIR /app
COPY --from=build /src /src

EXPOSE 8080
CMD ["bash","-lc","find /src -name '*.jar' -o -name '*.war' | sed -n '1,80p' && echo 'Update CMD to run the correct artifact.' && sleep infinity"]
