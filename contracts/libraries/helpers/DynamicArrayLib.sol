// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {DataTypes} from "../types/DataTypes.sol";

library DynamicArrayLib {
    using SafeMath for uint256;

    /**
     * @dev find a value in array
     * @param array The dynamic array
     * @param value value to find
     * @return (index, found)
     **/
    function find(DataTypes.DynamicArray storage array, uint256 value)
        internal
        view
        returns (uint256, bool)
    {
        require(array.length > 0, "Array is empty!");
        for (uint256 i = 0; i < array.length; i++) {
            if (array.value[i] == value) {
                return (i, true);
            }
        }
        return (0, false);
    }

    /**
     * @dev add a value to array
     * @param array The dynamic array
     * @param value value to find
     **/
    function push(DataTypes.DynamicArray storage array, uint256 value)
        internal
    {
        uint256 index = array.length;
        array.value[index] = value;
        array.length = array.length.add(1);
    }

    /**
     * @dev remove element at index
     * @param array The dynamic array
     * @param index index to remove
     **/
    function removeAtIndex(DataTypes.DynamicArray storage array, uint256 index)
        internal
    {
        require(array.length > index, "Array have not that index");

        if (array.length == 1) {
            array.length = 0;
        } else {
            array.value[index] = array.value[array.length - 1];
            array.length = array.length.sub(1);
        }
    }

    /**
     * @dev remove first element equal value
     * @param array The dynamic array
     * @param value value to remove
     **/
    function removeAtValue(DataTypes.DynamicArray storage array, uint256 value)
        internal
    {
        require(array.length > 0, "Array is empty!");

        (uint256 index, bool found) = find(array, value);

        if (found == true) {
            removeAtIndex(array, index);
        }
    }
}
