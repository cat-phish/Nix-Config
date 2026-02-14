CXX := g++
CXXFLAGS := -std=c++17 -Wall -Wextra -pedantic -g

APP := main
TESTS := tests

APP_SRCS := main.cpp
TEST_SRCS := tests.cpp

APP_OBJS := $(APP_SRCS:.cpp=.o)
TEST_OBJS := $(TEST_SRCS:.cpp=.o)

.PHONY: all clean

all: $(APP) $(TESTS)

$(APP): $(APP_OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $^

$(TESTS): $(TEST_OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $^

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -f $(APP) $(TESTS) $(APP_OBJS) $(TEST_OBJS)
