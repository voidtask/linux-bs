import subprocess
import shlex
import io
from typing import Union, Iterable


def run_command(command: Union[str, Iterable[str]]) -> str:
    """
    Executes a system command and returns the standard output as a string.

    Uses duck typing: accepts anything that behaves like a string (has a 'split' method)
    or anything that behaves like an iterable (list, tuple, etc.).
    """

    if hasattr(command, "split"):
        cmd_args = shlex.split(command)
    else:
        cmd_args = list(command)

    try:
        result = subprocess.run(cmd_args, capture_output=True, text=True, check=True)
        return result.stdout

    except subprocess.CalledProcessError as e:
        return f"Command failed with exit code {e.returncode}.\nError: {e.stderr}"
    except FileNotFoundError:
        return f"Error: Command '{cmd_args[0]}' not found on this system."
    except TypeError:
        return "Error: Invalid command format provided."


my_packages = set(filter(lambda s: s != "", run_command("pacman -Qqe").splitlines()))
list_packages = set(filter(lambda s: s != "", run_command("cat list.txt").splitlines()))

installed_but_not_listed = my_packages.difference(list_packages)

if len(installed_but_not_listed) > 0:
    print(
        "There are missing packages in the list.txt compared to current installed ones:"
    )
    print(", ".join(installed_but_not_listed))
    print("")
    answer = input("Would you like to add them to the list? [Y/N] ")

    if answer == "Y":
        all_lines: list[str] = []
        with open("list.txt", "r", encoding="utf-8") as fp:
            all_lines.extend(fp.readlines())

        all_lines.extend([f"{s}\n" for s in installed_but_not_listed])

        should_sort = input("Should the list.txt be sorted? [Y/N] ")
        if should_sort == "Y":
            all_lines.sort()

        with open("list.txt", "w", encoding="utf-8") as fp:
            fp.writelines(all_lines)
            print("Done!")
    else:
        print("Nothing was done!")

else:
    print(
        "All of the packages explicitly installed on this system are present in the list.txt"
    )
