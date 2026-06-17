FROM eclipse-temurin:17

COPY Fortify_SCA_and_Apps_25.2.0_linux_x64.run /tmp/

RUN chmod +x /tmp/Fortify_SCA_and_Apps_25.2.0_linux_x64.run && \
    /tmp/Fortify_SCA_and_Apps_25.2.0_linux_x64.run --mode unattended

ENV PATH=$PATH:/opt/Fortify/Fortify_SCA_and_Apps_25.2.0/bin