/*
// $Id$
// Package org.eigenbase is a class library of data management components.
// Copyright (C) 2005-2005 The Eigenbase Project
// Copyright (C) 2005-2005 Disruptive Tech
// Copyright (C) 2005-2005 LucidEra, Inc.
//
// This program is free software; you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the Free
// Software Foundation; either version 2 of the License, or (at your option)
// any later version approved by The Eigenbase Project.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/
package org.eigenbase.rel;

import org.eigenbase.relopt.*;
import org.eigenbase.rex.*;

/**
 * <code>FilterRelBase</code> is an abstract base class for implementations
 * of {@link FilterRel}.
 *
 * @author John V. Sichi
 * @version $Id$
 */
public abstract class FilterRelBase extends SingleRel
{
    //~ Instance fields -------------------------------------------------------

    public final RexNode condition;

    //~ Constructors ----------------------------------------------------------

    /**
     * Creates a filter.
     *
     * @param cluster {@link RelOptCluster} this relational expression
     *        belongs to
     * @param traits the traits of this rel
     * @param child input relational expression
     * @param condition boolean expression which determines whether a row is
     *        allowed to pass
     */
    protected FilterRelBase(
        RelOptCluster cluster,
        RelTraitSet traits,
        RelNode child,
        RexNode condition)
    {
        super(cluster, traits, child);
        this.condition = condition;
    }

    //~ Methods ---------------------------------------------------------------

    public RexNode [] getChildExps()
    {
        return new RexNode [] { condition };
    }

    public RelOptCost computeSelfCost(RelOptPlanner planner)
    {
        double dRows = getRows();
        double dCpu = child.getRows();
        double dIo = 0;
        return planner.makeCost(dRows, dCpu, dIo);
    }

    // override RelNode
    public double getRows()
    {
        return child.getRows() * RexUtil.getSelectivity(condition);
    }

    public void explain(RelOptPlanWriter pw)
    {
        pw.explain(
            this,
            new String [] { "child", "condition" });
    }
}

// End FilterRelBase.java