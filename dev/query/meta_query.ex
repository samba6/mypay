defmodule MyPayWeb.Query.Meta do
  @doc false
  def all_fields_fragment do
    name = "MetaAllFieldsFragment"

    fragment = """
      fragment #{name} on Meta {
        id
        _id
        breakTimeSecs
        payPerHr
        nightSupplPayPct
        sundaySupplPayPct

        insertedAt
        updatedAt
      }
    """

    {name, fragment}
  end

  @doc false
  def create do
    {frag_name, frag} = all_fields_fragment()

    """
    mutation CreateMeta($meta: CreateMetaInput!) {
      meta(meta: $meta) {
        ...#{frag_name}
      }
    }

    #{frag}
    """
  end

  def all_metas do
    {frag_name, frag} = all_fields_fragment()

    """
    query GetAllMetas($metaInput: GetMetaInput ) {
      metas(meta: $metaInput) {
        ...#{frag_name}
      }
    }
    #{frag}
    """
  end
end
