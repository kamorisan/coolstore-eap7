# EAP 8.1 Runtime Image for CoolStore (Mirrored to OpenShift Internal Registry)
FROM image-registry.openshift-image-registry.svc:5000/workshop-images/eap81-runtime:8.1

# Copy provisioned server from Maven build
COPY --chown=jboss:root target/server /opt/server

# Copy PostgreSQL JDBC module
COPY --chown=jboss:root s2i/eap-install/modules/ /opt/server/modules/

# Fix permissions for OpenShift (non-root user in arbitrary UID)
RUN chown -R jboss:0 /opt/server && \
    chmod -R g+rwX /opt/server

# Expose HTTP port
EXPOSE 8080

# Run as non-root user
USER jboss

# Start EAP
CMD ["/opt/server/bin/standalone.sh", "-b", "0.0.0.0"]
