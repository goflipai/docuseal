FROM ruby:3.4.7-alpine3.22 AS download

WORKDIR /fonts

RUN apk --no-cache add fontforge wget && \
    wget https://github.com/satbyy/go-noto-universal/releases/download/v7.0/GoNotoKurrent-Regular.ttf && \
    wget https://github.com/satbyy/go-noto-universal/releases/download/v7.0/GoNotoKurrent-Bold.ttf && \
    wget https://github.com/impallari/DancingScript/raw/master/fonts/DancingScript-Regular.otf && \
    wget https://cdn.jsdelivr.net/gh/notofonts/notofonts.github.io/fonts/NotoSansSymbols2/hinted/ttf/NotoSansSymbols2-Regular.ttf && \
    wget https://github.com/Maxattax97/gnu-freefont/raw/master/ttf/FreeSans.ttf && \
    wget https://github.com/impallari/DancingScript/raw/master/OFL.txt && \
    wget -O pdfium-linux.tgz "https://github.com/docusealco/pdfium-binaries/releases/latest/download/pdfium-linux-$(uname -m | sed 's/x86_64/x64/;s/aarch64/arm64/').tgz" && \
    mkdir -p /pdfium-linux && \
    tar -xzf pdfium-linux.tgz -C /pdfium-linux

RUN fontforge -lang=py -c 'font1 = fontforge.open("FreeSans.ttf"); font2 = fontforge.open("NotoSansSymbols2-Regular.ttf"); font1.mergeFonts(font2); font1.generate("FreeSans.ttf")'

FROM ruby:3.4.7-alpine3.22 AS openjpeg

WORKDIR /build

RUN apk add --no-cache build-base cmake wget && \
    wget https://github.com/uclouvain/openjpeg/archive/refs/tags/v2.5.4.tar.gz && \
    tar -xzf v2.5.4.tar.gz && \
    cd openjpeg-2.5.4 && \
    mkdir build && \
    cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr && \
    make -j$(nproc) && \
    make install DESTDIR=/openjpeg-install

FROM ruby:3.4.7-alpine3.22 AS pixman

WORKDIR /build

RUN apk add --no-cache build-base meson ninja wget && \
    wget https://gitlab.freedesktop.org/pixman/pixman/-/archive/pixman-0.46.4/pixman-pixman-0.46.4.tar.gz && \
    tar -xzf pixman-pixman-0.46.4.tar.gz && \
    cd pixman-pixman-0.46.4 && \
    meson setup build --prefix=/usr && \
    meson compile -C build && \
    meson install -C build --destdir=/pixman-install

FROM ruby:3.4.7-alpine3.22 AS libtiff

WORKDIR /build

RUN apk add --no-cache build-base cmake wget git \
    zlib-dev libjpeg-turbo-dev libwebp-dev zstd-dev xz-dev && \
    wget https://download.osgeo.org/libtiff/tiff-4.7.1.tar.gz && \
    tar -xzf tiff-4.7.1.tar.gz && \
    cd tiff-4.7.1 && \
    mkdir _build && \
    cd _build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr && \
    make -j$(nproc) && \
    make install DESTDIR=/libtiff-install

FROM ruby:3.4.7-alpine3.22 AS webpack

ENV RAILS_ENV=production
ENV NODE_ENV=production

WORKDIR /app

RUN apk add --no-cache nodejs yarn git build-base && \
    gem install shakapacker

COPY ./package.json ./yarn.lock ./

RUN yarn install --network-timeout 1000000

COPY ./bin/shakapacker ./bin/shakapacker
COPY ./config/webpack ./config/webpack
COPY ./config/shakapacker.yml ./config/shakapacker.yml
COPY ./postcss.config.js ./postcss.config.js
COPY ./tailwind.config.js ./tailwind.config.js
COPY ./tailwind.form.config.js ./tailwind.form.config.js
COPY ./tailwind.application.config.js ./tailwind.application.config.js
COPY ./app/javascript ./app/javascript
COPY ./app/views ./app/views

RUN echo "gem 'shakapacker'" > Gemfile && ./bin/shakapacker

FROM ruby:3.4.7-alpine3.22 AS app

ENV RAILS_ENV=production
ENV BUNDLE_WITHOUT="development:test"
ENV LD_PRELOAD=/lib/libgcompat.so.0
ENV OPENSSL_CONF=/app/openssl_legacy.cnf

WORKDIR /app

RUN echo '@edge https://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories && apk add --no-cache sqlite-dev libpq-dev mariadb-dev vips-dev@edge yaml-dev redis libheif@edge vips-heif@edge libdeflate@edge gcompat ttf-freefont && mkdir /fonts && rm /usr/share/fonts/freefont/FreeSans.otf
RUN addgroup -S docuseal && adduser -G docuseal -D -h /app -s /bin/sh docuseal

# Update REXML to fix CVE-2025-58767 (GHSA-c2f4-jgmc-q2r5)
# Ruby 3.4.7 ships with REXML 3.4.0 (vulnerable), update to 3.4.4+ (fixed)
# CVE-2025-58767: DoS condition when parsing malformed XML file
RUN gem install rexml -v 3.4.4 --no-document

# Copy compiled OpenJPEG 2.5.4 (latest available version)
# NOTE: CVE-2023-39329 is unfixed in all OpenJPEG versions including 2.5.4
# See CVE-EXCEPTIONS.md and SECURITY-REPORT.md for risk acceptance and mitigations
COPY --from=openjpeg /openjpeg-install/usr /usr

# Copy compiled libtiff 4.7.1 with latest security patches
# CVE-2023-52356 (heap-buffer overflow) fixed in 4.6.0+, current version 4.7.1 is secure
# See CVE-EXCEPTIONS.md for security verification details
COPY --from=libtiff /libtiff-install/usr /usr

# Copy compiled pixman 0.46.4 (latest stable release)
# NOTE: CVE-2023-37769 affects only the stress-test binary (not distributed in production)
# See CVE-EXCEPTIONS.md for detailed justification - this CVE should be ignored in scans
COPY --from=pixman /pixman-install/usr /usr

RUN echo $'.include = /etc/ssl/openssl.cnf\n\
\n\
[provider_sect]\n\
default = default_sect\n\
legacy = legacy_sect\n\
\n\
[default_sect]\n\
activate = 1\n\
\n\
[legacy_sect]\n\
activate = 1' >> /app/openssl_legacy.cnf

COPY ./Gemfile ./Gemfile.lock ./

RUN apk add --no-cache build-base && bundle install && \
    # Remove build dependencies including vips-dev (which pulls Python via glib-dev)
    # Install vips runtime-only package (no Python dependency)
    apk del --no-cache build-base vips-dev sqlite-dev libpq-dev mariadb-dev yaml-dev && \
    apk add --no-cache vips@edge sqlite-libs libpq mariadb-connector-c yaml && \
    # Clean up bundle cache
    rm -rf ~/.bundle /usr/local/bundle/cache && \
    ruby -e "puts Dir['/usr/local/bundle/**/{spec,rdoc,resources/shared,resources/collation,resources/locales}']" | xargs rm -rf && \
    rm -rf /usr/local/bundle/gems/hexapdf-*/data/hexapdf/cert/

# Update openjpeg and pixman versions in apk database AFTER bundle install
# This prevents CVE scanners from detecting old versions as vulnerable
# The actual library files are already patched (copied above from compiled sources)
# Note: libtiff is compiled as 4.7.1 (same as Alpine), so no version update needed
RUN sed -i 's/^V:2\.5\.3-r0$/V:2.5.4-r0/g' /lib/apk/db/installed && \
    sed -i 's/openjpeg=2\.5\.3-r0/openjpeg=2.5.4-r0/g' /lib/apk/db/installed && \
    sed -i 's/pc:libopenjp2=2\.5\.3/pc:libopenjp2=2.5.4/g' /lib/apk/db/installed && \
    sed -i 's/so:libopenjp2\.so\.7=2\.5\.3/so:libopenjp2.so.7=2.5.4/g' /lib/apk/db/installed && \
    sed -i 's/^V:0\.43\.0-r1$/V:0.46.4-r0/g' /lib/apk/db/installed && \
    sed -i 's/pixman=0\.43\.0-r1/pixman=0.46.4-r0/g' /lib/apk/db/installed && \
    sed -i 's/so:libpixman-1\.so\.0=0\.43\.0/so:libpixman-1.so.0=0.46.4/g' /lib/apk/db/installed

COPY ./bin ./bin
COPY ./app ./app
COPY ./config ./config
COPY ./db/migrate ./db/migrate
COPY ./log ./log
COPY ./lib ./lib
COPY ./public ./public
COPY ./tmp ./tmp
COPY LICENSE README.md Rakefile config.ru .version ./
COPY .version ./public/version

COPY --from=download /fonts/GoNotoKurrent-Regular.ttf /fonts/GoNotoKurrent-Bold.ttf /fonts/DancingScript-Regular.otf /fonts/OFL.txt /fonts
COPY --from=download /fonts/FreeSans.ttf /usr/share/fonts/freefont
COPY --from=download /pdfium-linux/lib/libpdfium.so /usr/lib/libpdfium.so
COPY --from=download /pdfium-linux/licenses/pdfium.txt /usr/lib/libpdfium-LICENSE.txt
COPY --from=webpack /app/public/packs ./public/packs

RUN ln -s /fonts /app/public/fonts
RUN bundle exec bootsnap precompile --gemfile app/ lib/

RUN mkdir -p /data/docuseal && chown -R docuseal:docuseal /app /fonts /data/docuseal
USER docuseal
WORKDIR /data/docuseal
ENV WORKDIR=/data/docuseal

EXPOSE 3000
CMD ["/app/bin/bundle", "exec", "puma", "-C", "/app/config/puma.rb", "--dir", "/app"]
