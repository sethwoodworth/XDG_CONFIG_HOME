from typing import List
from kitty.boss import boss
from kittens.tui.handler import result_handler


def main(args: List[str]) -> str:
    cmd = input("Enter a command to be run headless")
    return cmd


# @result_handler(type_of_input="text")
def handle_result(
    args: List[str], answer: str, target_window_id: int, boss: Boss
) -> None:
    w = boss.windnow_id_map.get(target_window_id)
