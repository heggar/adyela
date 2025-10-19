"""
Unit tests for DateTimeRange value object
"""
from datetime import UTC, datetime, timedelta

import pytest

from adyela_api_appointments.domain.exceptions import InvalidTimeRangeError
from adyela_api_appointments.domain.value_objects import DateTimeRange


class TestDateTimeRange:
    """Test suite for DateTimeRange value object"""

    def test_create_valid_time_range(self):
        """Test creating a valid time range"""
        # Arrange
        start = datetime.now(UTC)
        end = start + timedelta(hours=1)

        # Act
        time_range = DateTimeRange(start=start, end=end)

        # Assert
        assert time_range.start == start
        assert time_range.end == end

    def test_create_invalid_time_range_fails(self):
        """Test that creating invalid time range raises error"""
        # Arrange
        start = datetime.now(UTC)
        end = start - timedelta(hours=1)  # End before start

        # Act & Assert
        with pytest.raises(InvalidTimeRangeError) as exc_info:
            DateTimeRange(start=start, end=end)

        assert "before" in str(exc_info.value).lower()

    def test_create_same_start_and_end_fails(self):
        """Test that start == end is invalid"""
        # Arrange
        now = datetime.now(UTC)

        # Act & Assert
        with pytest.raises(InvalidTimeRangeError):
            DateTimeRange(start=now, end=now)

    def test_duration_minutes(self):
        """Test calculating duration in minutes"""
        # Arrange
        start = datetime.now(UTC)
        end = start + timedelta(hours=2, minutes=30)
        time_range = DateTimeRange(start=start, end=end)

        # Act
        duration = time_range.duration_minutes

        # Assert
        assert duration == 150  # 2.5 hours = 150 minutes

    def test_overlaps_with_true(self, future_time_range, overlapping_time_range):
        """Test detecting overlapping time ranges"""
        # Act
        overlaps = future_time_range.overlaps_with(overlapping_time_range)

        # Assert
        assert overlaps is True

    def test_overlaps_with_false(self, future_time_range, non_overlapping_time_range):
        """Test non-overlapping time ranges"""
        # Act
        overlaps = future_time_range.overlaps_with(non_overlapping_time_range)

        # Assert
        assert overlaps is False

    def test_overlaps_partial_start(self):
        """Test overlap when second range starts during first range"""
        # Arrange
        range1 = DateTimeRange(
            start=datetime(2025, 1, 1, 10, 0, tzinfo=UTC),
            end=datetime(2025, 1, 1, 11, 0, tzinfo=UTC),
        )
        range2 = DateTimeRange(
            start=datetime(2025, 1, 1, 10, 30, tzinfo=UTC),
            end=datetime(2025, 1, 1, 11, 30, tzinfo=UTC),
        )

        # Act & Assert
        assert range1.overlaps_with(range2) is True
        assert range2.overlaps_with(range1) is True

    def test_overlaps_partial_end(self):
        """Test overlap when first range ends during second range"""
        # Arrange
        range1 = DateTimeRange(
            start=datetime(2025, 1, 1, 10, 0, tzinfo=UTC),
            end=datetime(2025, 1, 1, 11, 30, tzinfo=UTC),
        )
        range2 = DateTimeRange(
            start=datetime(2025, 1, 1, 11, 0, tzinfo=UTC),
            end=datetime(2025, 1, 1, 12, 0, tzinfo=UTC),
        )

        # Act & Assert
        assert range1.overlaps_with(range2) is True
        assert range2.overlaps_with(range1) is True

    def test_overlaps_contained(self):
        """Test overlap when one range is completely contained in another"""
        # Arrange
        range1 = DateTimeRange(
            start=datetime(2025, 1, 1, 10, 0, tzinfo=UTC),
            end=datetime(2025, 1, 1, 12, 0, tzinfo=UTC),
        )
        range2 = DateTimeRange(
            start=datetime(2025, 1, 1, 10, 30, tzinfo=UTC),
            end=datetime(2025, 1, 1, 11, 30, tzinfo=UTC),
        )

        # Act & Assert
        assert range1.overlaps_with(range2) is True
        assert range2.overlaps_with(range1) is True

    def test_adjacent_ranges_dont_overlap(self):
        """Test that adjacent but not overlapping ranges return false"""
        # Arrange
        range1 = DateTimeRange(
            start=datetime(2025, 1, 1, 10, 0, tzinfo=UTC),
            end=datetime(2025, 1, 1, 11, 0, tzinfo=UTC),
        )
        range2 = DateTimeRange(
            start=datetime(2025, 1, 1, 11, 0, tzinfo=UTC),  # Starts exactly when range1 ends
            end=datetime(2025, 1, 1, 12, 0, tzinfo=UTC),
        )

        # Act & Assert
        assert range1.overlaps_with(range2) is False
        assert range2.overlaps_with(range1) is False

    def test_contains_datetime(self):
        """Test checking if a datetime is within range"""
        # Arrange
        time_range = DateTimeRange(
            start=datetime(2025, 1, 1, 10, 0, tzinfo=UTC),
            end=datetime(2025, 1, 1, 11, 0, tzinfo=UTC),
        )
        inside = datetime(2025, 1, 1, 10, 30, tzinfo=UTC)
        outside_before = datetime(2025, 1, 1, 9, 30, tzinfo=UTC)
        outside_after = datetime(2025, 1, 1, 11, 30, tzinfo=UTC)
        at_end = datetime(2025, 1, 1, 11, 0, tzinfo=UTC)

        # Act & Assert
        assert time_range.contains(inside) is True
        assert time_range.contains(outside_before) is False
        assert time_range.contains(outside_after) is False
        assert time_range.contains(at_end) is False  # End is exclusive

    def test_str_representation(self):
        """Test string representation"""
        # Arrange
        start = datetime(2025, 1, 1, 10, 0, tzinfo=UTC)
        end = datetime(2025, 1, 1, 11, 0, tzinfo=UTC)
        time_range = DateTimeRange(start=start, end=end)

        # Act
        str_repr = str(time_range)

        # Assert
        assert start.isoformat() in str_repr
        assert end.isoformat() in str_repr
        assert " - " in str_repr
