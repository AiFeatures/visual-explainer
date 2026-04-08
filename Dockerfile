# Stage 1: Prepare skill files
FROM node:22-alpine AS build
WORKDIR /app
COPY package.json ./
COPY plugins/ plugins/
COPY install-pi.sh ./

# Stage 2: Serve templates via nginx
FROM nginx:stable-alpine AS runtime

LABEL org.opencontainers.image.source="https://github.com/AiFeatures/visual-explainer"
LABEL org.opencontainers.image.description="Visual Explainer skill — HTML templates and docs"

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY --from=build /app/plugins/visual-explainer/templates/ /usr/share/nginx/html/templates/
COPY --from=build /app/plugins/visual-explainer/SKILL.md /usr/share/nginx/html/
COPY --from=build /app/plugins/visual-explainer/commands/ /usr/share/nginx/html/commands/
COPY --from=build /app/plugins/visual-explainer/references/ /usr/share/nginx/html/references/

RUN chown -R appuser:appgroup /usr/share/nginx/html \
    && chown -R appuser:appgroup /var/cache/nginx \
    && chown -R appuser:appgroup /var/log/nginx \
    && touch /var/run/nginx.pid \
    && chown appuser:appgroup /var/run/nginx.pid

# Run nginx on unprivileged port
RUN sed -i 's/listen\s*80;/listen 8080;/' /etc/nginx/conf.d/default.conf

EXPOSE 8080

USER appuser

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -qO- http://localhost:8080/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
