/*
// $Id$
// Fennel is a relational database kernel.
// Copyright (C) 2004-2004 John V. Sichi.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public License
// as published by the Free Software Foundation; either version 2.1
// of the License, or (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/

#ifndef Fennel_ExecStreamGenerator_Included
#define Fennel_ExecStreamGenerator_Included

#include "fennel/exec/MockProducerExecStream.h"
#include "fennel/exec/DynamicParam.h"
#include <algorithm>
#include <numeric>

FENNEL_BEGIN_NAMESPACE

/**
 * Test data generators, usually for a 45-degree ramp 
 * (output value equals input row number).
 * 
 * @author John V. Sichi
 * @version $Id$
 */
class RampExecStreamGenerator : public MockProducerExecStreamGenerator
{
protected:
    int offset;
public:
    RampExecStreamGenerator(int offset_) {
        offset = offset_;
    }

    RampExecStreamGenerator() {
        offset = 0;
    }

    virtual int64_t generateValue(uint iRow, uint iCol)
    {
        return iRow + offset;
    }
};

/**
 * @author John V. Sichi
 */
class PermutationGenerator : public MockProducerExecStreamGenerator
{
    std::vector<int64_t> values;
    
public:
    explicit PermutationGenerator(uint nRows)
    {
        values.resize(nRows);
        std::iota(values.begin(), values.end(), 0);
        std::random_shuffle(values.begin(), values.end());
    }
    
    virtual int64_t generateValue(uint iRow, uint iCol)
    {
        // iCol ignored
        return values[iRow];
    }
};

/**
 * A Staircase Generator
 * Outputs numbers according to the formula:
 * Height * (row / (int) Width)
 * 
 * @author Wael Chatila
 * @version $Id$
 */
class StairCaseExecStremGenerator : public MockProducerExecStreamGenerator
{
    int h;
    int w;
public:
    StairCaseExecStremGenerator(int height, uint width) :
        h(height),
        w(width)
    {
        // empty
    }

    virtual int64_t generateValue(uint iRow, uint iCol)
    {
        return h * (iRow / w);
    }
};

/**
 * Outputs the value of a specified dynamic param, reinterpreted as int64_t
 * 
 * @author Wael Chatila
 */
class DynamicParamExecStreamGenerator :  public MockProducerExecStreamGenerator
{
    std::string dynamicParamId;
    DynamicParamManager &paramManager;

public:
    DynamicParamExecStreamGenerator(std::string &dynamicParamId_, 
                                    DynamicParamManager &paramManager_) :
        dynamicParamId(dynamicParamId_),
        paramManager(paramManager_)
    {
        // empty
    }

    virtual int64_t generateValue(uint iRow, uint iCol)
    {
        int64_t value = *reinterpret_cast<int64_t const *>(
            paramManager.getParam(dynamicParamId).getDatum().pData);
        return value;
    }
};


FENNEL_END_NAMESPACE

#endif

// End ExecStreamGenerator.h