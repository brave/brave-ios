INSTALL   = install -c
MKDIR     = mkdir -p
PREFIX    = /usr/local
LIBDIR    = $(PREFIX)/lib
INCDIR    = $(PREFIX)/include/CppUnitLite

AR		   = ar
RM         = rm -f
CC	       = g++
CPPFLAGS   = -g -O2 -Wall
LDFLAGS	   = 

SOURCES = $(wildcard *.cpp)
OBJECTS = $(SOURCES:%.cpp=%.o)
INCTARGET = $(wildcard *.h)
LIBTARGET = libCppUnitLite.a

all : $(LIBTARGET)

$(OBJECTS): %.o: %.cpp
	$(CC) -c $< -o $@ $(CPPFLAGS)

$(LIBTARGET): $(OBJECTS)
	$(AR) -cq $@ $^

%.d: %.cpp
	$(CC) -M $(CPPFLAGS) $< > $@.$$$$; \
	sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$

-include $(SOURCES:.cpp=.d)

clean:
	$(RM) $(SOURCES:%.cpp=%.d)
	$(RM) $(OBJECTS)

distclean: clean
	$(RM) $(LIBTARGET)

install: all
	$(MKDIR)   $(LIBDIR)
	$(INSTALL) $(LIBTARGET) $(LIBDIR)
	$(MKDIR)   $(INCDIR)
	$(INSTALL) $(INCTARGET) $(INCDIR)

uninstall:
	rm -f $(LIBDIR)/$(LIBTARGET)
	@for h in $(INCTARGET); do\
		rm -f $(INCDIR)/$$h;\
	done
	-rmdir $(LIBDIR)
	-rmdir $(INCDIR)