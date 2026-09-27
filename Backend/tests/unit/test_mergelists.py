import asyncio

import mergelists as ml


class TestMergeTwoLists:
    """Test the mergeTwoLists function with various branch coverage scenarios."""

    def test_equal_length_lists(self):
        """Test merging two lists of equal length."""
        result = ml.mergeTwoLists([1, 2, 3], [4, 5, 6])
        assert result == [1, 4, 2, 5, 3, 6]

    def test_first_list_longer(self):
        """Test merging when first list is longer."""
        result = ml.mergeTwoLists([1, 2, 3, 4], [5, 6])
        assert result == [1, 5, 2, 6, 3, 4]

    def test_second_list_longer(self):
        """Test merging when second list is longer."""
        result = ml.mergeTwoLists([1, 2], [3, 4, 5, 6])
        assert result == [1, 3, 2, 4, 5, 6]

    def test_first_list_empty(self):
        """Test merging when first list is empty."""
        result = ml.mergeTwoLists([], [1, 2, 3])
        assert result == [1, 2, 3]

    def test_second_list_empty(self):
        """Test merging when second list is empty."""
        result = ml.mergeTwoLists([1, 2, 3], [])
        assert result == [1, 2, 3]

    def test_both_lists_empty(self):
        """Test merging when both lists are empty."""
        result = ml.mergeTwoLists([], [])
        assert result == []

    def test_single_element_lists(self):
        """Test merging two single-element lists."""
        result = ml.mergeTwoLists([1], [2])
        assert result == [1, 2]

    def test_single_element_first_empty_second(self):
        """Test single element in first list, empty second."""
        result = ml.mergeTwoLists([1], [])
        assert result == [1]

    def test_empty_first_single_element_second(self):
        """Test empty first list, single element in second."""
        result = ml.mergeTwoLists([], [1])
        assert result == [1]

    def test_string_elements(self):
        """Test merging lists with string elements."""
        result = ml.mergeTwoLists(["a", "b"], ["c", "d"])
        assert result == ["a", "c", "b", "d"]

    def test_mixed_type_elements(self):
        """Test merging lists with mixed type elements."""
        result = ml.mergeTwoLists([1, "a", 2.5], [True, None, {}])
        assert result == [1, True, "a", None, 2.5, {}]

    def test_large_lists(self):
        """Test merging large lists."""
        list_1 = list(range(0, 1000, 2))
        list_2 = list(range(1, 1000, 2))
        result = ml.mergeTwoLists(list_1, list_2)
        # result should interleave: [0, 1, 2, 3, ..., 998, 999]
        assert len(result) == 1000
        assert result[0] == 0
        assert result[1] == 1


class TestMergeThreeLists:
    """Test the mergeThreeLists function with various branch coverage scenarios."""

    def test_equal_length_lists(self, capsys):
        """Test merging three lists of equal length."""
        result = ml.mergeThreeLists([1, 2], [3, 4], [5, 6])
        captured = capsys.readouterr()
        assert captured.out == "Merging lists of sizes: 2, 2, 2\n"
        assert result == [1, 3, 5, 2, 4, 6]

    def test_first_two_longer_than_third(self, capsys):
        """Test when first two lists are longer than third (i < n and j < m branch)."""
        result = ml.mergeThreeLists([1, 2, 3], [4, 5, 6], [7])
        captured = capsys.readouterr()
        assert "Merging lists of sizes: 3, 3, 1" in captured.out
        # After the loop: i=1, j=1, k=1
        # i < n and j < m: mergeTwoLists([2, 3], [5, 6])
        assert result == [1, 4, 7, 2, 5, 3, 6]

    def test_first_and_third_longer_than_second(self, capsys):
        """Test when first and third lists are longer (i < n and k < o branch)."""
        result = ml.mergeThreeLists([1, 2, 3], [4], [5, 6, 7])
        captured = capsys.readouterr()
        assert "Merging lists of sizes: 3, 1, 3" in captured.out
        # After the loop: i=1, j=1, k=1
        # i < n and k < o: mergeTwoLists([2, 3], [6, 7])
        assert result == [1, 4, 5, 2, 6, 3, 7]

    def test_second_and_third_longer_than_first(self, capsys):
        """Test when second and third lists are longer (j < m and k < o branch)."""
        result = ml.mergeThreeLists([1], [2, 3, 4], [5, 6, 7])
        captured = capsys.readouterr()
        assert "Merging lists of sizes: 1, 3, 3" in captured.out
        # After the loop: i=1, j=1, k=1
        # j < m and k < o: mergeTwoLists([3, 4], [6, 7])
        assert result == [1, 2, 5, 3, 6, 4, 7]

    def test_only_first_list_has_remainder(self, capsys):
        """Test when only first list has remaining elements (i < n branch)."""
        result = ml.mergeThreeLists([1, 2, 3], [4], [5])
        captured = capsys.readouterr()
        assert "Merging lists of sizes: 3, 1, 1" in captured.out
        # After the loop: i=1, j=1, k=1
        # Only i < n: extend with [2, 3]
        assert result == [1, 4, 5, 2, 3]

    def test_only_second_list_has_remainder(self, capsys):
        """Test when only second list has remaining elements (j < m branch)."""
        result = ml.mergeThreeLists([1], [2, 3, 4], [5])
        captured = capsys.readouterr()
        assert "Merging lists of sizes: 1, 3, 1" in captured.out
        # After the loop: i=1, j=1, k=1
        # Only j < m: extend with [3, 4]
        assert result == [1, 2, 5, 3, 4]

    def test_only_third_list_has_remainder(self, capsys):
        """Test when only third list has remaining elements (k < o branch)."""
        result = ml.mergeThreeLists([1], [2], [3, 4, 5])
        captured = capsys.readouterr()
        assert "Merging lists of sizes: 1, 1, 3" in captured.out
        # After the loop: i=1, j=1, k=1
        # Only k < o: extend with [4, 5]
        assert result == [1, 2, 3, 4, 5]

    def test_all_empty_lists(self, capsys):
        """Test when all lists are empty."""
        result = ml.mergeThreeLists([], [], [])
        captured = capsys.readouterr()
        assert "Merging lists of sizes: 0, 0, 0" in captured.out
        assert result == []

    def test_two_empty_one_element(self, capsys):
        """Test two empty lists and one with an element."""
        result = ml.mergeThreeLists([1], [], [])
        captured = capsys.readouterr()
        assert "Merging lists of sizes: 1, 0, 0" in captured.out
        # Loop doesn't run: i < n and j < m is False
        # Only i < n: extend with [1]
        assert result == [1]

    def test_single_elements_all_lists(self, capsys):
        """Test when each list has a single element."""
        result = ml.mergeThreeLists([1], [2], [3])
        captured = capsys.readouterr()
        assert "Merging lists of sizes: 1, 1, 1" in captured.out
        assert result == [1, 2, 3]

    def test_strings_in_lists(self, capsys):
        """Test with string elements."""
        result = ml.mergeThreeLists(["a", "b"], ["c", "d"], ["e", "f"])
        captured = capsys.readouterr()
        assert "Merging lists of sizes: 2, 2, 2" in captured.out
        assert result == ["a", "c", "e", "b", "d", "f"]


class TestMergeKLists:
    """Test the mergeKLists async function with various scenarios."""

    def test_merge_two_lists_directly(self):
        """Test merging exactly two lists via mergeKLists."""
        result = asyncio.run(ml.mergeKLists([[1, 2], [3, 4]]))
        assert result == [1, 3, 2, 4]

    def test_merge_single_list(self):
        """Test mergeKLists with a single list returns it as-is."""
        result = asyncio.run(ml.mergeKLists([[1, 2, 3]]))
        assert result == [1, 2, 3]

    def test_merge_empty_list_of_lists(self):
        """Test mergeKLists with empty list of lists."""
        result = asyncio.run(ml.mergeKLists([]))
        assert result == []

    def test_merge_four_lists_recursively(self):
        """Test mergeKLists with four lists (requires recursion)."""
        result = asyncio.run(ml.mergeKLists([[1, 2], [3, 4], [5, 6], [7, 8]]))
        # First recursion: mergeKLists([[5,6], [7,8]]) and mergeKLists([[1,2], [3,4]])
        # Then merge results: mergeTwoLists([5,6,7,8], [1,2,3,4])
        # Wait, let me trace through this more carefully
        # len(lists) = 4, half = 2
        # lists_1 = lists[2:] = [[5,6], [7,8]]
        # lists_2 = lists[:2] = [[1,2], [3,4]]
        # So we recursively call mergeKLists on those
        # Left recursion (lists_1=[[5,6], [7,8]]): mergeTwoLists([5,6], [7,8]) = [5,7,6,8]
        # Right recursion (lists_2=[[1,2], [3,4]]): mergeTwoLists([1,2], [3,4]) = [1,3,2,4]
        # Then mergeTwoLists([5,7,6,8], [1,3,2,4]) = [5,1,7,3,6,2,8,4]
        assert result == [5, 1, 7, 3, 6, 2, 8, 4]

    def test_merge_three_lists_recursively(self):
        """Test mergeKLists with three lists (requires recursion)."""
        result = asyncio.run(ml.mergeKLists([[1, 2], [3, 4], [5, 6]]))
        # len(lists) = 3, half = 1
        # lists_1 = lists[1:] = [[3,4], [5,6]]
        # lists_2 = lists[:1] = [[1,2]]
        # Left recursion (lists_1): mergeKLists([[3,4], [5,6]]) -> len=2 -> mergeTwoLists([3,4], [5,6]) = [3,5,4,6]
        # Right recursion (lists_2): mergeKLists([[1,2]]) -> len=1 -> returns [1,2]
        # Then mergeTwoLists([3,5,4,6], [1,2]) = [3,1,5,2,4,6]
        assert result == [3, 1, 5, 2, 4, 6]

    def test_merge_single_element_lists(self):
        """Test merging multiple single-element lists."""
        result = asyncio.run(ml.mergeKLists([[1], [2], [3], [4]]))
        assert result == [3, 1, 4, 2]

    def test_merge_two_empty_lists(self):
        """Test merging two empty lists."""
        result = asyncio.run(ml.mergeKLists([[], []]))
        assert result == []

    def test_merge_mixed_empty_nonempty_lists(self):
        """Test merging mix of empty and non-empty lists."""
        result = asyncio.run(ml.mergeKLists([[], [1, 2]]))
        assert result == [1, 2]

    def test_merge_eight_small_lists(self):
        """Test merging eight lists for deeper recursion."""
        lists = [[1], [2], [3], [4], [5], [6], [7], [8]]
        result = asyncio.run(ml.mergeKLists(lists))
        # len = 8, half = 4
        # lists_1 = [[5], [6], [7], [8]]
        # lists_2 = [[1], [2], [3], [4]]
        # We need to trace through the recursion
        # This is complex, but we're mainly testing the recursion works
        assert len(result) == 8
        assert all(x in result for x in range(1, 9))

    def test_merge_uneven_list_sizes(self):
        """Test merging lists of different sizes."""
        result = asyncio.run(ml.mergeKLists([[1, 2, 3], [4], [5, 6]]))
        # len = 3, half = 1
        # lists_1 = [[4], [5,6]]
        # lists_2 = [[1,2,3]]
        # Left: mergeKLists([[4], [5,6]]) -> mergeTwoLists([4], [5,6]) = [4,5,6]
        # Right: mergeKLists([[1,2,3]]) -> [1,2,3]
        # Then mergeTwoLists([4,5,6], [1,2,3]) = [4,1,5,2,6,3]
        assert result == [4, 1, 5, 2, 6, 3]

    def test_merge_large_list_count(self):
        """Test merging many lists."""
        lists = [[i] for i in range(16)]
        result = asyncio.run(ml.mergeKLists(lists))
        # Should contain all values 0-15
        assert len(result) == 16
        assert set(result) == set(range(16))

    def test_merge_preserves_order_within_lists(self):
        """Test that relative order within each list is preserved."""
        lists = [[10, 20, 30], [40, 50, 60], [70, 80, 90]]
        result = asyncio.run(ml.mergeKLists(lists))
        # Verify elements from each list maintain relative order
        list1_elements = [x for x in result if x in [10, 20, 30]]
        list2_elements = [x for x in result if x in [40, 50, 60]]
        list3_elements = [x for x in result if x in [70, 80, 90]]
        assert list1_elements == [10, 20, 30]
        assert list2_elements == [40, 50, 60]
        assert list3_elements == [70, 80, 90]
