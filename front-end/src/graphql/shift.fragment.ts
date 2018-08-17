import gql from "graphql-tag";

export const shiftFragment = gql`
  fragment ShiftFragment on Shift {
    id
    _id
    date
    startTime
    endTime
    hoursGross
    normalHours
    normalPay
    nightHours
    nightSupplPay
    sundayHours
    sundaySupplPay
    totalPay
    meta {
      id
    }
    typename__
  }
`;

export default shiftFragment;
