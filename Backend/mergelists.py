import asyncio


async def mergeKLists(lists: list) -> list:

    if len(lists) == 2:
        return mergeTwoLists(lists[0], lists[1])

    if len(lists) == 1:
        return lists[0]

    if not lists:
        return []

    half = len(lists) // 2
    lists_1 = lists[half:]
    lists_2 = lists[:half]

    tasks = [mergeKLists(lists_1), mergeKLists(lists_2)]
    results = await asyncio.gather(*tasks)

    lists_1_r = results[0]
    lists_2_r = results[1]

    return mergeTwoLists(lists_1_r, lists_2_r)


"""
class to merge lists together element wise.

current types:
merge 2 lists
merge 3 lists
"""

"""
merges the 2 given lists element wise
ie adds the first element of each lists to the result, and the second element of each list, etc
"""


def mergeTwoLists(list_1: list, list_2: list) -> list:
    n = len(list_1)
    m = len(list_2)
    i = 0
    j = 0
    combined = []
    while i < n and j < m:
        combined.append(list_1[i])
        combined.append(list_2[j])
        i += 1
        j += 1

    if i < n:
        combined.extend(list_1[i:])

    if j < m:
        combined.extend(list_2[j:])

    return combined


"""
Merges the 3 given lists element wise
ie adds the first element of each lists to the result, and the second element of each list, etc
"""


def mergeThreeLists(list_1: list, list_2: list, list_3: list) -> list:
    n = len(list_1)
    m = len(list_2)
    o = len(list_3)
    print(f"Merging lists of sizes: {n}, {m}, {o}")
    i = 0
    j = 0
    k = 0
    combined = []

    while i < n and j < m and k < o:
        combined.append(list_1[i])
        combined.append(list_2[j])
        combined.append(list_3[k])
        i += 1
        j += 1
        k += 1

    if i < n and j < m:
        combined.extend(mergeTwoLists(list_1[i:], list_2[j:]))

    elif i < n and k < o:
        combined.extend(mergeTwoLists(list_1[i:], list_3[k:]))

    elif j < m and k < o:
        combined.extend(mergeTwoLists(list_2[j:], list_3[k:]))

    elif i < n:
        combined.extend(list_1[i:])

    elif j < m:
        combined.extend(list_2[j:])

    elif k < o:
        combined.extend(list_3[k:])

    return combined
