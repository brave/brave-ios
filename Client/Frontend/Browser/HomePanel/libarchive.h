// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

//From https://github.com/libarchive/libarchive/blob/master/libarchive/archive.h

#ifndef libarchive_h
#define libarchive_h

//archive.h

#define      ARCHIVE_EOF                1          /* Found end of archive. */
#define      ARCHIVE_OK                 0          /* Operation was successful. */
#define      ARCHIVE_RETRY            (-10)        /* Retry might succeed. */
#define      ARCHIVE_WARN             (-20)        /* Partial success. */
#define      ARCHIVE_FAILED           (-25)        /* Current operation cannot complete. */
#define      ARCHIVE_FATAL            (-30)        /* No more operations are possible. */

struct archive;
struct archive_entry;

int               archive_version_number(void);
const char *      archive_version_string(void);
int               archive_version_stamp(void);
const char *      archive_version(void);
int               archive_api_version(void);
int               archive_api_feature(void);
struct            archive *archive_read_new(void);
int               archive_read_support_compression_all(struct archive *);
int               archive_read_support_compression_bzip2(struct archive *);
int               archive_read_support_compression_compress(struct archive *);
int               archive_read_support_compression_gzip(struct archive *);
int               archive_read_support_compression_none(struct archive *);
int               archive_read_support_compression_program(struct archive *, const char *command);
int               archive_read_support_format_all(struct archive *);
int               archive_read_support_format_ar(struct archive *);
int               archive_read_support_format_cpio(struct archive *);
int               archive_read_support_format_empty(struct archive *);
int               archive_read_support_format_gnutar(struct archive *);
int               archive_read_support_format_iso9660(struct archive *);
int               archive_read_support_format_mtree(struct archive *);
int               archive_read_support_format_tar(struct archive *);
int               archive_read_support_format_zip(struct archive *);
int               archive_read_open_filename(struct archive *, const char *_filename, size_t _block_size);
int               archive_read_open_file(struct archive *, const char *_filename, size_t _block_size);
int               archive_read_open_memory(struct archive *, void * buff, size_t size);
int               archive_read_open_memory2(struct archive *a, void *buff, size_t size, size_t read_size);
int               archive_read_open_fd(struct archive *, int _fd, size_t _block_size);
int               archive_read_open_FILE(struct archive *, FILE *_file);
int               archive_read_next_header(struct archive *, struct archive_entry **);
int64_t           archive_read_header_position(struct archive *);
ssize_t           archive_read_data(struct archive *, void *, size_t);
int               archive_read_data_block(struct archive *a, const void **buff, size_t *size, off_t *offset);
int               archive_read_data_skip(struct archive *);
int               archive_read_data_into_buffer(struct archive *, void *buffer, ssize_t len);
int               archive_read_data_into_fd(struct archive *, int fd);
int               archive_read_extract(struct archive *, struct archive_entry *, int flags);
void              archive_read_extract_set_progress_callback(struct archive *, void (*_progress_func)(void *), void *_user_data);
void              archive_read_extract_set_skip_file(struct archive *, dev_t, ino_t);
int               archive_read_close(struct archive *);
int               archive_read_finish(struct archive *);
//void              archive_read_finish(struct archive *);
struct            archive *archive_write_new(void);
int               archive_write_set_bytes_per_block(struct archive *, int bytes_per_block);
int               archive_write_get_bytes_per_block(struct archive *);
int               archive_write_set_bytes_in_last_block(struct archive *, int bytes_in_last_block);
int               archive_write_get_bytes_in_last_block(struct archive *);
int               archive_write_set_skip_file(struct archive *, dev_t, ino_t);
int               archive_write_set_compression_bzip2(struct archive *);
int               archive_write_set_compression_compress(struct archive *);
int               archive_write_set_compression_gzip(struct archive *);
int               archive_write_set_compression_none(struct archive *);
int               archive_write_set_compression_program(struct archive *, const char *cmd);
int               archive_write_set_format(struct archive *, int format_code);
int               archive_write_set_format_by_name(struct archive *, const char *name);
int               archive_write_set_format_ar_bsd(struct archive *);
int               archive_write_set_format_ar_svr4(struct archive *);
int               archive_write_set_format_cpio(struct archive *);
int               archive_write_set_format_cpio_newc(struct archive *);
int               archive_write_set_format_pax(struct archive *);
int               archive_write_set_format_pax_restricted(struct archive *);
int               archive_write_set_format_shar(struct archive *);
int               archive_write_set_format_shar_dump(struct archive *);
int               archive_write_set_format_ustar(struct archive *);
int               archive_write_open_fd(struct archive *, int _fd);
int               archive_write_open_filename(struct archive *, const char *_file);
int               archive_write_open_file(struct archive *, const char *_file);
int               archive_write_open_FILE(struct archive *, FILE *);
int               archive_write_open_memory(struct archive *, void *_buffer, size_t _buffSize, size_t *_used);
int               archive_write_header(struct archive *, struct archive_entry *);
ssize_t           archive_write_data(struct archive *, const void *, size_t);
ssize_t           archive_write_data_block(struct archive *, const void *, size_t, off_t);
int               archive_write_finish_entry(struct archive *);
int               archive_write_close(struct archive *);
int               archive_write_finish(struct archive *);
struct            archive *archive_write_disk_new(void);
int               archive_write_disk_set_skip_file(struct archive *, dev_t, ino_t);
int               archive_write_disk_set_options(struct archive *, int flags);
int               archive_write_disk_set_standard_lookup(struct archive *);
int               archive_write_disk_set_group_lookup(struct archive *, void *private_data, gid_t (*loookup)(void *, const char *gname, gid_t gid), void (*cleanup)(void *));
int               archive_write_disk_set_user_lookup(struct archive *, void *private_data, uid_t (*)(void *, const char *uname, uid_t uid), void (*cleanup)(void *));
int64_t           archive_position_compressed(struct archive *);
int64_t           archive_position_uncompressed(struct archive *);
const char *      archive_compression_name(struct archive *);
int               archive_compression(struct archive *);
int               archive_errno(struct archive *);
const char *      archive_error_string(struct archive *);
const char *      archive_format_name(struct archive *);
int               archive_format(struct archive *);
void              archive_clear_error(struct archive *);
void              archive_set_error(struct archive *, int _err, const char *fmt, ...);
void              archive_copy_error(struct archive *dest, struct archive *src);



//archive_entry.h

time_t            archive_entry_atime(struct archive_entry *);
long              archive_entry_atime_nsec(struct archive_entry *);
time_t            archive_entry_ctime(struct archive_entry *);
long              archive_entry_ctime_nsec(struct archive_entry *);
dev_t             archive_entry_dev(struct archive_entry *);
dev_t             archive_entry_devmajor(struct archive_entry *);
dev_t             archive_entry_devminor(struct archive_entry *);
mode_t            archive_entry_filetype(struct archive_entry *);
void              archive_entry_fflags(struct archive_entry *, unsigned long *set, unsigned long *clear);
const char*       archive_entry_fflags_text(struct archive_entry *);
gid_t             archive_entry_gid(struct archive_entry *);
const char*       archive_entry_gname(struct archive_entry *);
const wchar_t*    archive_entry_gname_w(struct archive_entry *);
const char*       archive_entry_hardlink(struct archive_entry *);
const wchar_t*    archive_entry_hardlink_w(struct archive_entry *);
ino_t             archive_entry_ino(struct archive_entry *);
mode_t            archive_entry_mode(struct archive_entry *);
time_t            archive_entry_mtime(struct archive_entry *);
long              archive_entry_mtime_nsec(struct archive_entry *);
unsigned int      archive_entry_nlink(struct archive_entry *);
const char*       archive_entry_pathname(struct archive_entry *);
const wchar_t*    archive_entry_pathname_w(struct archive_entry *);
dev_t             archive_entry_rdev(struct archive_entry *);
dev_t             archive_entry_rdevmajor(struct archive_entry *);
dev_t             archive_entry_rdevminor(struct archive_entry *);
int64_t           archive_entry_size(struct archive_entry *);
const char*       archive_entry_strmode(struct archive_entry *);
const char*       archive_entry_symlink(struct archive_entry *);
const wchar_t*    archive_entry_symlink_w(struct archive_entry *);
uid_t             archive_entry_uid(struct archive_entry *);
const char*       archive_entry_uname(struct archive_entry *);
const wchar_t*    archive_entry_uname_w(struct archive_entry *);

#endif /* libarchive_h */

