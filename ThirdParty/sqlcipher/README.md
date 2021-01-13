# Updating sqlcipher

1. In a separate folder somewhere, run:
    ```
    git clone --depth 1 --branch <tag_name> https://github.com/sqlcipher/sqlcipher
    cd sqlcipher
    ./configure --with-crypto-lib=none
    make sqlite3.c
    ```
2. Copy/Overwrite `sqlite3.c`, `sqlite3.h`, `sqlite3ext.h`, and `sqlite3session.h` to the projects directory (`sqlcipher`)
3. Run `create_xcframework.sh`
