#
# EPITECH PROJECT, 2026
# main.c
# File description:
# apply function
#

NAME        := robot-factory
TEST_NAME   := unit_tests

SRC_DIR     := src
OBJ_DIR     := obj
INC_DIR     := include
INC_SUBDIR  := include/
TEST_DIR    := tests

# Utilisation de find en bash pour récupérer les fichiers .c
SRC         := $(shell find $(SRC_DIR) -type f -name "*.c")

# Exclusion de main.c pour éviter les doubles définitions lors des tests
SRC_TESTS   := $(shell find $(SRC_DIR) -type f -name "*.c" ! -name "main.c")
TESTS_SRC   := $(shell find $(TEST_DIR) -type f -name "*.c")

OBJ         := $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(SRC))
OBJ_TESTS   := $(patsubst $(SRC_DIR)/%.c,$(OBJ_DIR)/%.o,$(SRC_TESTS)) \
               $(patsubst $(TEST_DIR)/%.c,$(OBJ_DIR)/$(TEST_DIR)/%.o,$(TESTS_SRC))

DEP         := $(OBJ:.o=.d) $(OBJ_TESTS:.o=.d)

CC          := epiclang
CFLAGS      := -Wall -Wextra
CPPFLAGS    := -I$(INC_DIR) -I$(INC_SUBDIR)
LDFLAGS     :=

NPROC       := $(shell nproc 2>/dev/null || echo 4)
MAKEFLAGS   += -j$(NPROC)

all: $(NAME)

$(NAME): $(OBJ)
	@echo "[LINK] $@"
	@$(CC) $^ -o $@ $(LDFLAGS)

# Compilation des fichiers sources
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(dir $@)
	@echo "[CC] $<"
	@$(CC) $(CFLAGS) $(CPPFLAGS) -MMD -MP -c $< -o $@

# Compilation des fichiers de tests
$(OBJ_DIR)/$(TEST_DIR)/%.o: $(TEST_DIR)/%.c
	@mkdir -p $(dir $@)
	@echo "[CC TEST] $<"
	@$(CC) $(CFLAGS) $(CPPFLAGS) -MMD -MP -c $< -o $@

# Édition de liens pour les tests (Une seule définition)
$(TEST_NAME): $(OBJ_TESTS)
	@echo "[LINK TESTS] $@"
	@$(CC) $^ -o $@ $(LDFLAGS)

-include $(DEP)

# Règle sécurisée pour les tests (gcovr, coverage et HTML)
tests_run:
	@$(MAKE) fclean
	@$(MAKE) $(TEST_NAME) CC=gcc CFLAGS="$(CFLAGS) --coverage" LDFLAGS="$(LDFLAGS) -lcriterion --coverage"
	@echo "[EXEC] $(TEST_NAME)"
	@./$(TEST_NAME)
	@echo "\n=== COVERAGE TABLE ==="
	@gcovr --exclude $(TEST_DIR)/ 
	@echo "\n=== GENERATING HTML REPORT ==="
	@mkdir -p coverage_report
	@gcovr --exclude $(TEST_DIR)/ --html-details coverage_report/index.html
	@echo "Report generated in coverage_report/index.html"

# Règle sécurisée et indépendante pour Valgrind (ignore les échecs de tests pour lire valgrind)
tests_valgrind:
	@$(MAKE) fclean
	@$(MAKE) $(TEST_NAME) CC=gcc CFLAGS="$(CFLAGS) -g3" LDFLAGS="$(LDFLAGS) -lcriterion -g3"
	@echo "[VALGRIND] $(TEST_NAME)"
	@valgrind --leak-check=full --track-origins=yes --trace-children=yes ./$(TEST_NAME) --jobs=1 || true

clean:
	@rm -rf $(OBJ_DIR) coverage_report
	@find . -type f \( -name "*.gcno" -o -name "*.gcda" \) -delete

fclean: clean
	@rm -f $(NAME) $(TEST_NAME)

re: fclean all

.NOTPARALLEL: re #exec en seq si re sinon parallel (par apport au -j (jobs))
.PHONY: all clean fclean re tests_run tests_valgrind