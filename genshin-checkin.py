from json import loads
from json.decoder import JSONDecodeError
import argparse
import asyncio
import sys
import genshin


async def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-c", "--config", metavar="CONFIG", default="cookies.json",
                        help="the config file location, defaults to 'cookies.json'",
                        type=str, action="store")
    args = parser.parse_args()
    with open(args.config, 'r', encoding="ascii") as cfg_file:
        try:
            cfg = loads(cfg_file.read())
        except JSONDecodeError as err:
            print(f"Failed to parse config file:\n  {err}")
            return 1
        client = genshin.Client(cfg)
        client.USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.5060.53 Safari/537.36"
        client.default_game = genshin.Game.GENSHIN
        try:
            result = await client.claim_daily_reward()
        except genshin.AlreadyClaimed:
            print("You have already checked in.")
            return 0
        except genshin.InvalidCookies:
            print("Failed to check in, cookies are not valid.")
            return 1
        else:
            print(f"Successfully checked in. Got {result.amount} {result.name}(s).")


if __name__ == "__main__":
    ret = asyncio.run(main())
    sys.exit(ret)
