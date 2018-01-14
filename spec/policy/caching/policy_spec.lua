local resty_lrucache = require('resty.lrucache')

describe('policy', function()
  describe('.export', function()
    describe('when configured as strict', function()
      local caching_policy
      local cache
      local ctx  -- the caching policy will add the handler here

      before_each(function()
        local config = { caching_type = 'strict' }
        caching_policy = require('apicast.policy.caching').new(config)
        ctx = { }
        caching_policy:rewrite(ctx)
        cache = resty_lrucache.new(1)
      end)

      it('caches authorized requests', function()
        ctx.cache_handler(cache, 'a_key', { status = 200 }, nil)
        assert.equals(200, cache:get('a_key'))
      end)

      it('clears the cache entry for a request when it is denied', function()
        cache:set('a_key', 200)

        ctx.cache_handler(cache, 'a_key', { status = 403 }, nil)
        assert.is_nil(cache:get('a_key'))
      end)

      it('clears the cache entry for a request when it fails', function()
        cache:set('a_key', 200)

        ctx.cache_handler(cache, 'a_key', { status = 500 }, nil)
        assert.is_nil(cache:get('a_key'))
      end)
    end)

    describe('when configured as resilient', function()
      local caching_policy
      local cache
      local ctx  -- the caching policy will add the handler here

      before_each(function()
        local config = { caching_type = 'resilient' }
        caching_policy = require('apicast.policy.caching').new(config)
        ctx = { }
        caching_policy:rewrite(ctx)
        cache = resty_lrucache.new(1)
      end)

      it('caches authorized requests', function()
        ctx.cache_handler(cache, 'a_key', { status = 200 }, nil)
        assert.equals(200, cache:get('a_key'))
      end)

      it('caches denied requests', function()
        ctx.cache_handler(cache, 'a_key', { status = 403 }, nil)
        assert.equals(403, cache:get('a_key'))
      end)

      it('does not clear the cache entry for a request when it fails', function()
        cache:set('a_key', 200)

        ctx.cache_handler(cache, 'a_key', { status = 500 }, nil)
        assert.equals(200, cache:get('a_key'))
      end)
    end)
  end)
end)
