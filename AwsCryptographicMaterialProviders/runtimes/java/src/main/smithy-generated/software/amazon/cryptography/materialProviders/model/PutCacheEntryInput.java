// Copyright Amazon.com Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
// Do not modify this file. This file is machine generated, and any changes to it will be overwritten.
package software.amazon.cryptography.materialProviders.model;

import java.nio.ByteBuffer;
import java.util.Objects;

public class PutCacheEntryInput {
  private final ByteBuffer identifier;

  private final Materials materials;

  private final long creationTime;

  private final long expiryTime;

  private final int messagesUsed;

  private final int bytesUsed;

  protected PutCacheEntryInput(BuilderImpl builder) {
    this.identifier = builder.identifier();
    this.materials = builder.materials();
    this.creationTime = builder.creationTime();
    this.expiryTime = builder.expiryTime();
    this.messagesUsed = builder.messagesUsed();
    this.bytesUsed = builder.bytesUsed();
  }

  public ByteBuffer identifier() {
    return this.identifier;
  }

  public Materials materials() {
    return this.materials;
  }

  public long creationTime() {
    return this.creationTime;
  }

  public long expiryTime() {
    return this.expiryTime;
  }

  public int messagesUsed() {
    return this.messagesUsed;
  }

  public int bytesUsed() {
    return this.bytesUsed;
  }

  public Builder toBuilder() {
    return new BuilderImpl(this);
  }

  public static Builder builder() {
    return new BuilderImpl();
  }

  public interface Builder {
    Builder identifier(ByteBuffer identifier);

    ByteBuffer identifier();

    Builder materials(Materials materials);

    Materials materials();

    Builder creationTime(long creationTime);

    long creationTime();

    Builder expiryTime(long expiryTime);

    long expiryTime();

    Builder messagesUsed(int messagesUsed);

    int messagesUsed();

    Builder bytesUsed(int bytesUsed);

    int bytesUsed();

    PutCacheEntryInput build();
  }

  static class BuilderImpl implements Builder {
    protected ByteBuffer identifier;

    protected Materials materials;

    protected long creationTime;

    protected long expiryTime;

    protected int messagesUsed;

    protected int bytesUsed;

    protected BuilderImpl() {
    }

    protected BuilderImpl(PutCacheEntryInput model) {
      this.identifier = model.identifier();
      this.materials = model.materials();
      this.creationTime = model.creationTime();
      this.expiryTime = model.expiryTime();
      this.messagesUsed = model.messagesUsed();
      this.bytesUsed = model.bytesUsed();
    }

    public Builder identifier(ByteBuffer identifier) {
      this.identifier = identifier;
      return this;
    }

    public ByteBuffer identifier() {
      return this.identifier;
    }

    public Builder materials(Materials materials) {
      this.materials = materials;
      return this;
    }

    public Materials materials() {
      return this.materials;
    }

    public Builder creationTime(long creationTime) {
      this.creationTime = creationTime;
      return this;
    }

    public long creationTime() {
      return this.creationTime;
    }

    public Builder expiryTime(long expiryTime) {
      this.expiryTime = expiryTime;
      return this;
    }

    public long expiryTime() {
      return this.expiryTime;
    }

    public Builder messagesUsed(int messagesUsed) {
      this.messagesUsed = messagesUsed;
      return this;
    }

    public int messagesUsed() {
      return this.messagesUsed;
    }

    public Builder bytesUsed(int bytesUsed) {
      this.bytesUsed = bytesUsed;
      return this;
    }

    public int bytesUsed() {
      return this.bytesUsed;
    }

    public PutCacheEntryInput build() {
      if (Objects.isNull(this.identifier()))  {
        throw new IllegalArgumentException("Missing value for required field `identifier`");
      }
      if (Objects.isNull(this.materials()))  {
        throw new IllegalArgumentException("Missing value for required field `materials`");
      }
      if (Objects.isNull(this.creationTime()))  {
        throw new IllegalArgumentException("Missing value for required field `creationTime`");
      }
      if (Objects.nonNull(this.creationTime()) && this.creationTime() < 0) {
        throw new IllegalArgumentException("`creationTime` must be greater than or equal to 0");
      }
      if (Objects.isNull(this.expiryTime()))  {
        throw new IllegalArgumentException("Missing value for required field `expiryTime`");
      }
      if (Objects.nonNull(this.expiryTime()) && this.expiryTime() < 0) {
        throw new IllegalArgumentException("`expiryTime` must be greater than or equal to 0");
      }
      if (Objects.nonNull(this.messagesUsed()) && this.messagesUsed() < 0) {
        throw new IllegalArgumentException("`messagesUsed` must be greater than or equal to 0");
      }
      if (Objects.nonNull(this.bytesUsed()) && this.bytesUsed() < 0) {
        throw new IllegalArgumentException("`bytesUsed` must be greater than or equal to 0");
      }
      return new PutCacheEntryInput(this);
    }
  }
}
